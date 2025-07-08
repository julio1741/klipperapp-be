module Api
  module V1
    class UsersController < ApplicationController
      before_action :set_user, only: [:show, :update, :destroy, :start_day, :end_day]

      def index
        @users = @filtered_records || User.includes(:branches).all
        render json: @users.as_json(include: { role: {} })
      end

      def show
        render json: @users.as_json(include: { role: {} })
      end

      def create
        @user = User.new(user_params)
        if @user.save
          set_branches
          UserMailer.email_verification(@user).deliver_later
          render json: @user, status: :created
        else
          render json: @user.errors, status: :unprocessable_entity
        end
      end

      def update
        if @user.update(user_params)
          set_branches
          render json: @user
        else
          render json: @user.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @user.destroy
        head :no_content
      end

      def next_available
        service = AssignBarberService.new(
          organization_id: params[:organization_id],
          branch_id: params[:branch_id]
        )
        barber = service.call

        if barber
          render json: barber, status: :ok
        else
          render json: { error: "No barbero disponible" }, status: :not_found
        end
      end

      # get users working today
      def users_working_today
        organization_id = params[:organization_id]
        branch_id = params[:branch_id]
        role_id = params[:role_id]

        @users = User.users_working_today(organization_id, branch_id, role_id)

        users_with_queue_count = @users.map do |user|
          attendances = Attendance.where(attended_by: user.id, status: [:processing, :pending, :postponed])
            .where("attendances.created_at >= ? AND attendances.created_at <= ?", Time.now.in_time_zone('America/Santiago').beginning_of_day, Time.now.in_time_zone('America/Santiago').end_of_day)

          queue_count = attendances.count

          # Suma de la duración de todos los servicios de todas las attendances en la cola
          estimated_waiting_time = attendances.joins(:services).sum('services.duration')

          user.as_json(include: { role: {} }).merge(
            attendances_queue_count: queue_count,
            estimated_waiting_time: estimated_waiting_time
          )
        end

        render json: users_with_queue_count, status: :ok
      end

      def start_day
        if @user.start_shift!
          render json: { message: "Inicio de jornada registrado" }, status: :ok
        else
          render json: { error: "No se pudo iniciar jornada" }, status: :unprocessable_entity
        end
      end

      def end_day
        if @user.end_shift!
          render json: { message: "Fin de jornada registrado" }, status: :ok
        else
          render json: { error: "No se pudo finalizar jornada" }, status: :unprocessable_entity
        end
      end

      def start_attendance
        user_id = params[:user_id].presence
        attendance_id = params[:attendance_id].presence

        return render json: { error: "Falta user_id o attendance_id" }, status: :bad_request unless user_id && attendance_id

        @user = User.find_by(id: user_id)
        return render json: { error: "Usuario no encontrado" }, status: :not_found unless @user

        attendance = Attendance.find_by(id: attendance_id)
        return render json: { error: "Asistencia no encontrada" }, status: :not_found unless attendance

        if attendance.attended_by != @user.id
          return render json: { error: "El barbero no está asignado a esta asistencia" }, status: :forbidden
        end

        if @user.start_attendance!
          if attendance.may_start?
            attendance.start!
            attendance.send_message_to_frontend
          end
          render json: { message: "El barbero comenzó a atender" }, status: :ok
        else
          render json: { error: "No se pudo cambiar el estado a 'working'" }, status: :unprocessable_entity
        end
      end

      def end_attendance
        user_id = params[:user_id].presence
        attendance_id = params[:attendance_id].presence

        return render json: { error: "Falta user_id o attendance_id" }, status: :bad_request unless user_id && attendance_id

        @user = User.find_by(id: user_id)
        return render json: { error: "Usuario no encontrado" }, status: :not_found unless @user

        attendance = Attendance.find_by(id: attendance_id)
        return render json: { error: "Asistencia no encontrada" }, status: :not_found unless attendance

        if attendance.attended_by != @user.id
          render json: { error: "El barbero no está asignado a esta asistencia" }, status: :forbidden
          return
        end

        begin
          attendance.complete! if attendance.may_complete?
          @user.end_attendance! if @user.may_end_attendance?
          attendance.send_message_to_frontend
          attendance.set_profile_last_attended_date(attendance.profile_id)
          render json: { message: "El barbero terminó de atender" }, status: :ok
        rescue AASM::InvalidTransition => e
          Rails.logger.error "Error al finalizar asistencia: #{e.message}"
          render json: { error: "No se pudo cambiar el estado a 'available'" }, status: :unprocessable_entity
        end
      end

      def finish_attendance
        user_id = params[:user_id].presence
        attendance_id = params[:attendance_id].presence

        return render json: { error: "Falta user_id o attendance_id" }, status: :bad_request unless user_id && attendance_id

        @user = User.find_by(id: user_id)
        return render json: { error: "Usuario no encontrado" }, status: :not_found unless @user

        attendance = Attendance.find_by(id: attendance_id)
        return render json: { error: "Asistencia no encontrada" }, status: :not_found unless attendance

        attendance.assign_attributes(finish_attendance_params)
        attendance.finish!
        attendance.send_message_to_frontend
        render json: { message: "Asistencia finalizada correctamente" }, status: :ok
      end

      def postpone_attendance
        user_id = params[:user_id].presence
        attendance_id = params[:attendance_id].presence
        return render json: { error: "Falta user_id o attendance_id" }, status: :bad_request unless user_id && attendance_id
        @user = User.find_by(id: user_id)
        return render json: { error: "Usuario no encontrado" }, status: :not_found unless @user
        attendance = Attendance.find_by(id: attendance_id)
        return render json: { error: "Asistencia no encontrada" }, status: :not_found unless attendance

        if attendance.may_postpone?
          attendance.postpone!
          attendance.send_message_to_frontend
          render json: { message: "Asistencia pospuesta correctamente" }, status: :ok
        else
          render json: { error: "No se puede posponer esta asistencia" }, status: :unprocessable_entity
        end
      end

      def resume_attendance
        user_id = params[:user_id].presence
        attendance_id = params[:attendance_id].presence
        return render json: { error: "Falta user_id o attendance_id" }, status: :bad_request unless user_id && attendance_id
        @user = User.find_by(id: user_id)
        return render json: { error: "Usuario no encontrado" }, status: :not_found unless @user
        attendance = Attendance.find_by(id: attendance_id)
        return render json: { error: "Asistencia no encontrada" }, status: :not_found unless attendance
        if attendance.may_resume?
          attendance.resume!
          attendance.send_message_to_frontend
          render json: { message: "Asistencia reanudada correctamente" }, status: :ok
        else
          render json: { error: "No se puede reanudar esta asistencia" }, status: :unprocessable_entity
        end
      end

      def cancel_attendance
        user_id = params[:user_id].presence
        attendance_id = params[:attendance_id].presence
        comments = params[:comments].presence
        return render json: { error: "Falta user_id o attendance_id" }, status: :bad_request unless user_id && attendance_id
        @user = User.find_by(id: user_id)
        return render json: { error: "Usuario no encontrado" }, status: :not_found unless @user
        attendance = Attendance.find_by(id: attendance_id)
        return render json: { error: "Asistencia no encontrada" }, status: :not_found unless attendance
        if attendance.may_cancel?
          attendance.comments = comments if comments
          attendance.cancel!
          attendance.send_message_to_frontend
          render json: { message: "Asistencia cancelada correctamente" }, status: :ok
        else
          render json: { error: "No se puede cancelar esta asistencia" }, status: :unprocessable_entity
        end
      end

      def calculate_payment
        start_date = params[:start_date]
        end_date = params[:end_date]
        user_id = params[:user_id]
        branch_id = params[:branch_id]
        organization_id = params[:organization_id]
        role_name = params[:role_name]

        result = PaymentService.new(
          start_date: start_date,
          end_date: end_date,
          user_id: user_id,
          branch_id: branch_id,
          role_name: role_name,
          organization_id: organization_id
        ).perform

        render json: result, status: :ok
      end

      # POST /api/v1/users/reset_password
      def reset_password
        user = User.find_by(email: params[:email])
        unless user
          render json: { error: 'Usuario no encontrado' }, status: :not_found and return
        end

        # Generar nuevo código de verificación y marcar como no verificado
        user.email_verification_code = SecureRandom.hex(3).upcase
        user.email_verified = false
        if user.save
          Rails.logger.info "Nuevo código de verificación generado: #{user.email_verification_code}"
          UserMailer.reset_verification_code(user).deliver_later
          render json: { message: 'Se envió un nuevo código de verificación al correo.' }, status: :ok
        else
          render json: { error: 'No se pudo generar el código de verificación', details: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/users/update_password
      def update_password
        user = User.find_by(id: params[:id])
        unless user
          render json: { error: 'Usuario no encontrado' }, status: :not_found and return
        end

        unless user.authenticate(params[:current_password])
          render json: { error: 'Contraseña actual incorrecta' }, status: :unauthorized and return
        end

        user.password = params[:new_password]
        user.password_confirmation = params[:new_password_confirmation]
        if user.save
          render json: { message: 'Contraseña actualizada correctamente' }, status: :ok
        else
          render json: { error: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/users/verify_email
      def verify_email
        user = User.find_by(email: params[:email])
        unless user
          render json: { error: 'Usuario no encontrado' }, status: :not_found and return
        end

        if user.email_verified
          render json: { message: 'El correo ya está verificado' }, status: :ok and return
        end

        if user.email_verification_code == params[:code]
          update_attrs = { email_verified: true, email_verification_code: nil }
          if params[:password].present?
            update_attrs[:password] = params[:password]
            update_attrs[:password_confirmation] = params[:password_confirmation] || params[:password]
          end
          if user.update(update_attrs)
            render json: { message: 'Correo verificado correctamente' }, status: :ok
          else
            render json: { error: user.errors.full_messages }, status: :unprocessable_entity
          end
        else
          render json: { error: 'Código de verificación incorrecto' }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/users/:id/not_available
      def not_available
        @user = User.find(params[:id])
        if @user.may_not_available?
          @user.not_available!
          render json: { message: 'Usuario disponible' }, status: :ok
        else
          render json: { error: 'No se puede poner como no disponible en este estado' }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/users/:id/available
      def available
        @user = User.find(params[:id])
        if @user.may_available?
          @user.available!
          render json: { message: 'Usuario no disponible' }, status: :ok
        else
          render json: { error: 'No se puede poner como disponible en este estado' }, status: :unprocessable_entity
        end
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      def set_branches
        if params[:branch_ids]
          @user.branch_ids = params[:branch_ids]
        end
      end

      def finish_attendance_params
        params.require(:attendance).permit(
          :discount, :extra_discount,
          :user_amount, :organization_amount, :total_amount, :trx_number, :tip_amount,
          :payment_method, service_ids: [], child_attendance_ids: []
        )
      end

      def user_params
        params.require(:user).permit(
          :name, :email, :phone_number, :address_line1, :address_line2,
          :city, :state, :zip_code, :country, :role_id, :branch_id,
          :organization_id, :active, :password, :password_confirmation,
          :photo_url, branch_ids: []
        )
      end
    end
  end
end
