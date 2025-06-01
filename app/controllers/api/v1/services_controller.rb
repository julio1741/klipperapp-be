module Api
  module V1
    class ServicesController < ApplicationController
      before_action :authorize_request
      before_action :set_service, only: [:show, :update, :destroy]

      def index
        @services = Service.all
        render json: @services
      end

      def show
        render json: @service
      end

      def create
        @service = Service.new(service_params)
        if @service.save
          render json: @service, status: :created
        else
          render json: @service.errors, status: :unprocessable_entity
        end
      end

      def update
        if @service.update(service_params)
          render json: @service
        else
          render json: @service.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @service.destroy
        head :no_content
      end

      private

      def set_service
        @service = Service.find(params[:id])
      end

      def service_params
        params.require(:service).permit(
          :name,
          :description,
          :organization_id,
          :price,
          :branch_id,
          :duration,
          :active
        )
      end
    end
  end
end
