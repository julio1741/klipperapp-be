module Api
  module V1
    class UsersController < ApplicationController
      before_action :set_user, only: [:show, :update, :destroy]

      def index
        @users = @filtered_records || User.includes(:branches).all
        render json: @users.to_json(include: :branches)
      end

      def show
        render json: @user.to_json(include: :branches)
      end

      def create
        @user = User.new(user_params)
        if @user.save
          set_branches
          render json: @user.to_json(include: :branches), status: :created
        else
          render json: @user.errors, status: :unprocessable_entity
        end
      end

      def update
        if @user.update(user_params)
          set_branches
          render json: @user.to_json(include: :branches)
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

      def start_day
        if @user.start_day! && @user.update(start_working_at: Time.current)
          render json: { message: "Inicio de jornada registrado" }, status: :ok
        else
          render json: { error: "No se pudo iniciar jornada" }, status: :unprocessable_entity
        end
      end

      def end_day
        if @user.end_day! && @user.update(start_working_at: nil)
          render json: { message: "Fin de jornada registrado" }, status: :ok
        else
          render json: { error: "No se pudo finalizar jornada" }, status: :unprocessable_entity
        end
      end

      def start_attendance
        if @user.start_attendance!
          render json: { message: "El barbero comenzó a atender" }, status: :ok
        else
          render json: { error: "No se pudo cambiar el estado a 'working'" }, status: :unprocessable_entity
        end
      end

      def end_attendance
        if @user.end_attendance!
          render json: { message: "El barbero terminó de atender" }, status: :ok
        else
          render json: { error: "No se pudo cambiar el estado a 'available'" }, status: :unprocessable_entity
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

      def user_params
        params.require(:user).permit(
          :name, :email, :phone_number, :address_line1, :address_line2,
          :city, :state, :zip_code, :country, :role_id,
          :organization_id, :active, :password, :password_confirmation,
          branch_ids: []
        )
      end
    end
  end
end
