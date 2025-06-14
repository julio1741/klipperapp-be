module Api
  module V1
    class OrganizationsController < ApplicationController
      before_action :set_organization, only: [:show, :update, :destroy]

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

      private

      def set_organization
        @organization = Organization.find(params[:id])
      end

      def organization_params
        params.require(:organization).permit(:name, :slug, :bio, metadata: {})
      end
    end
  end
end
