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
        reconciliation_date = params[:cash_reconciliation][:reconciliation_date].present? ? Date.parse(params[:cash_reconciliation][:reconciliation_date]) : Time.current.to_date

        reconciliation = @current_user.branch.cash_reconciliations.find_or_initialize_by(
          reconciliation_type: :closing,
          created_at: (reconciliation_date.beginning_of_day..reconciliation_date.end_of_day)
        )

        reconciliation.assign_attributes(cash_reconciliation_params.except(:reconciliation_date))
        reconciliation.user = @current_user unless reconciliation.persisted?
        reconciliation.organization = @current_user.organization unless reconciliation.persisted?
        reconciliation.created_at = reconciliation_date.end_of_day # Establecer la fecha de creación al final del día

        if reconciliation.save
          render json: reconciliation, status: reconciliation.previously_new_record? ? :created : :ok
        else
          render json: { errors: reconciliation.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def approve
        @reconciliation = CashReconciliation.find(params[:id])
        if @reconciliation.may_approve?
          @reconciliation.approved_at = Time.current
          @reconciliation.approved_by_user = @current_user
          @reconciliation.approve!
          render json: @reconciliation, status: :ok
        else
          render json: { error: "No se puede aprobar este arqueo de caja." }, status: :unprocessable_entity
        end
      end

      private

      def cash_reconciliation_params
        params.require(:cash_reconciliation).permit(
          :reconciliation_type,
          :cash_amount,
          :notes,
          :reconciliation_date, # Permitir el nuevo parámetro de fecha
          bank_balances: [:account_name, :balance]
        )
      end
    end
  end
end
