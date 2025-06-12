module Api
  module V1
    class ProfilesController < ApplicationController
      before_action :authorize_request
      before_action :set_profile, only: [:show, :update, :destroy]

      def index
        if params[:phone_number].present?
          @profile = Profile.find_by(phone_number: params[:phone_number])
          if @profile
            organizatiopn_id = @current_user.organization_id
            is_attended_today = Attendance.profile_in_attendance_today?(@profile.id)
            render json: { profile: @profile, is_attended_today: is_attended_today }
          else
            render json: { error: "Profile not found" }, status: :not_found
          end
        else
          @profiles = @filtered_records || Profile.all
          render json: @profiles
        end
      end

      def show
        render json: @profile
      end

      def create
        @profile = Profile.new(profile_params)
        if @profile.save
          render json: @profile, status: :created
        else
          render json: @profile.errors, status: :unprocessable_entity
        end
      end

      def update
        if @profile.update(profile_params)
          render json: @profile
        else
          render json: @profile.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @profile.destroy
        head :no_content
      end

      private

      def set_profile
        @profile = Profile.find(params[:id])
      end

      def profile_params
        params.require(:profile).permit(
          :name,
          :email,
          :birth_date,
          :phone_number,
          :organization_id,
          :branch_id
        )
      end
    end
  end
end
