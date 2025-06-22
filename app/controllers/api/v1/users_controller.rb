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

        render json: @users.as_json(include: { role: {} }), status: :ok
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
          attendance.start! if attendance.may_start?
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

        if @user.end_attendance!
          attendance.complete! if attendance.may_complete?
          attendance.set_profile_last_attended_date(attendance.profile_id)
          render json: { message: "El barbero terminó de atender" }, status: :ok
        else
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
        render json: { message: "Asistencia finalizada correctamente" }, status: :ok
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
          :user_amount, :organization_amount, :total_amount, :trx_number,
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
