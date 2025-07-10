module Api
  module V1
    class CashReconciliationsController < ApplicationController
      before_action :authorize_request

      def index
        reconciliations = CashReconciliation.where(branch_id: @current_user.branch_id).order(created_at: :desc)
        render json: reconciliations, status: :ok
      end

      def preview
        service = CashReconciliationService.new(@current_user.branch, params[:date])
        preview_data = service.perform_preview

        if preview_data[:error]
          render json: { error: preview_data[:error] }, status: :unprocessable_entity
        else
          render json: preview_data, status: :ok
        end
      end

      def create
        reconciliation = CashReconciliation.new(cash_reconciliation_params)
        reconciliation.user = @current_user
        reconciliation.branch = @current_user.branch
        reconciliation.organization = @current_user.organization

        if reconciliation.save
          render json: reconciliation, status: :created
        else
          render json: { errors: reconciliation.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def cash_reconciliation_params
        params.require(:cash_reconciliation).permit(
          :reconciliation_type,
          :cash_amount,
          :notes,
          bank_balances: [:account_name, :balance]
        )
      end
    end
  end
end
