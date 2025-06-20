module Api
  module V1
    class OrganizationsController < ApplicationController
      before_action :set_organization, only: [:show, :update, :destroy]
      before_action :authorize_request, only: [:clean, :build_queue, :show_queue, :build_queue]

      def index
        if params[:slug].present?
          organization = Organization.find_by(slug: params[:slug])
          if organization
            render json: organization
          else
            render json: { error: 'Organization not found' }, status: :not_found
          end
        else
          @organizations = @filtered_records || Organization.all
          render json: @organizations
        end
      end

      def show
        render json: @organization
      end

      def create
        @organization = Organization.new(organization_params)
        if @organization.save
          render json: @organization, status: :created
        else
          render json: @organization.errors, status: :unprocessable_entity
        end
      end

      def update
        if @organization.update(organization_params)
          render json: @organization
        else
          render json: @organization.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @organization.destroy
        head :no_content
      end

      def clean
        Attendance.cancel_old_pending_attendances
        User.set_users_stand_by
        Rails.cache.clear
        render json: { message: 'Entities cleaned successfully' }, status: :ok
      end

      def build_queue
        assign_service = UserQueueService.new(
          organization_id: @current_user.organization_id,
          branch_id: @current_user.branch_id,
          role_name: "agent")
        assign_service.build_queue
        render json: { message: 'Build queue sended' }, status: :ok
      end

      def show_queue
        assign_service = UserQueueService.new(
          organization_id: @current_user.organization_id,
          branch_id: @current_user.branch_id,
          role_name: "agent")
        users = assign_service.queue
        render json: users, status: :ok
      end

      private

      def set_organization
        @organization = Organization.find(params[:id])
      end

      def organization_params
        params.require(:organization).permit(:name, :slug, :bio, :photo_url, metadata: {})
      end
    end
  end
end
