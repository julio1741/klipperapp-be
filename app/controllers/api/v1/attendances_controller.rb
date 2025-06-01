module Api
  module V1
    class AttendancesController < ApplicationController
      before_action :authorize_request
      before_action :set_attendance, only: [:show, :update, :destroy]

      # GET /api/v1/attendances
      def index
        @attendances = Attendance.all
        render json: @attendances
      end

      # GET /api/v1/attendances/:id
      def show
        render json: @attendance
      end

      # POST /api/v1/attendances
      def create
        @attendance = Attendance.new(attendance_params)
        if @attendance.save
          render json: @attendance, status: :created
        else
          render json: @attendance.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/attendances/:id
      def update
        if @attendance.update(attendance_params)
          render json: @attendance
        else
          render json: @attendance.errors, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/attendances/:id
      def destroy
        @attendance.destroy
        head :no_content
      end

      private

      def set_attendance
        @attendance = Attendance.find(params[:id])
      end

      def attendance_params
        params.require(:attendance).permit(
          :status,
          :date,
          :time,
          :profile_id,
          :service_id,
          :organization_id,
          :branch_id
        )
      end
    end
  end
end
