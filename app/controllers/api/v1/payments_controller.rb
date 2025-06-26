module Api
  module V1
    class PaymentsController < ApplicationController
      before_action :set_payment, only: [:show, :update, :destroy, :approve, :reject, :cancel, :mark_success]

      def index
        @payments = @filtered_records || Payment.all
        if params[:starts_at].present? || params[:ends_at].present?
          starts_at = params[:starts_at].presence && DateTime.parse(params[:starts_at])
          ends_at = params[:ends_at].presence && DateTime.parse(params[:ends_at])

          @payments = @payments.where(
            "(starts_at >= ? OR ? IS NULL) AND (ends_at <= ? OR ? IS NULL)",
            starts_at, starts_at, ends_at, ends_at
          )
        end

        render json: @payments
      end

      def show
        render json: @payment
      end

      def create
        @payment = Payment.new(payment_params)

        if @payment.save
          render json: @payment, status: :created
        else
          Rails.logger.error(@payment.errors.full_messages.join(", "))
          render json: @payment.errors, status: :unprocessable_entity
        end
      end

      def update
        if @payment.update(payment_params)
          render json: @payment
        else
          render json: @payment.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @payment.destroy
        head :no_content
      end

      def approve
        if @payment.may_approve?
          @payment.approve!
          render json: @payment
        else
          render json: { error: "Cannot approve payment" }, status: :unprocessable_entity
        end
      end

      def reject
        if @payment.may_reject?
          @payment.reject!
          render json: @payment
        else
          render json: { error: "Cannot reject payment" }, status: :unprocessable_entity
        end
      end

      def cancel
        if @payment.may_cancel?
          @payment.cancel!
          render json: @payment
        else
          render json: { error: "Cannot cancel payment" }, status: :unprocessable_entity
        end
      end

      def mark_success
        if @payment.may_mark_success?
          @payment.mark_success!
          render json: @payment
        else
          render json: { error: "Cannot mark payment as success" }, status: :unprocessable_entity
        end
      end

      private

      def set_payment
        @payment = Payment.find(params[:id])
      end

      def payment_params
        params.require(:payment).permit(:amount, :organization_id, :branch_id, :user_id, :starts_at, :ends_at, :aasm_state)
      end
    end
  end
end
