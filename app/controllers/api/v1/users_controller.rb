module Api
  module V1
    class UsersController < ApplicationController
      before_action :set_user, only: [:show, :update, :destroy]

      def index
        @users = User.includes(:branches).all
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
