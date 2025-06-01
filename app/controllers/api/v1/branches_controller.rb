module Api
  module V1
    class BranchesController < ApplicationController
      before_action :authorize_request
      before_action :set_branch, only: [:show, :update, :destroy]

      def index
        @branches = Branch.all
        render json: @branches
      end

      def show
        render json: @branch
      end

      def create
        @branch = Branch.new(branch_params)
        if @branch.save
          render json: @branch, status: :created
        else
          render json: @branch.errors, status: :unprocessable_entity
        end
      end

      def update
        if @branch.update(branch_params)
          render json: @branch
        else
          render json: @branch.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @branch.destroy
        head :no_content
      end

      private

      def set_branch
        @branch = Branch.find(params[:id])
      end

      def branch_params
        params.require(:branch).permit(
          :name,
          :address_line1,
          :address_line2,
          :city,
          :state,
          :zip_code,
          :country,
          :phone_number,
          :email,
          :active,
          :organization_id
        )
      end
    end
  end
end
