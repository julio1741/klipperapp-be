module Api
  module V1
    class ExpensesController < ApplicationController
      before_action :authorize_request
      before_action :set_expense, only: [:show, :update, :destroy]

      # GET /api/v1/expenses
      def index
        @expenses = (@filtered_records || Expense).where(organization_id: @current_user.organization_id)
        render json: @expenses, status: :ok
      end

      # GET /api/v1/expenses/:id
      def show
        render json: @expense, status: :ok
      end

      # POST /api/v1/expenses
      def create
        @expense = Expense.new(expense_params)
        if @expense.save
          render json: @expense, status: :created
        else
          render json: @expense.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/expenses/:id
      def update
        if @expense.update(expense_params)
          render json: @expense, status: :ok
        else
          render json: @expense.errors, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/expenses/:id
      def destroy
        @expense.destroy
        head :no_content
      end

      private

      def set_expense
        @expense = Expense.find(params[:id])
      end

      def expense_params
        params.require(:expense).permit(:description, :amount, :organization_id, :user_id, :branch_id, :quantity, :type)
      end
    end
  end
end
