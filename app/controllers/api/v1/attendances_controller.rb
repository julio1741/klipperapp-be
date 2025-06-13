module Api
  module V1
    class AttendancesController < ApplicationController
      before_action :authorize_request
      before_action :set_attendance, only: [:show, :update, :destroy]

      # GET /api/v1/attendances
      def index
        @attendances = @filtered_records || Attendance.includes(:attended_by_user, :profile, :service)
          .where(status: [:pending, :processing, :completed, :finished])
          .order(:created_at)

        render json: @attendances.map { |attendance|
          attendance.as_json(include: {
            attended_by_user: {},
            profile: {},
            service: {}
          })
        }
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

      def by_users_queue
        organization_id = @current_user.organization_id
        branch_id = @current_user.branch_id
        role_id = params[:role_id]
        result = AvailableUsersQueueService.new(
          organization_id: organization_id,
          branch_id: branch_id,
          role_name: 'agent'
        ).call

        render json: result, status: :ok
      end
      # GET /api/v1/attendances/by_users_working_today
      def by_users_working_today
        organization_id = params[:organization_id]
        branch_id = params[:branch_id]
        role_id = params[:role_id]

        users = User.where(
          organization_id: organization_id,
          branch_id: branch_id,
          role_id: role_id
        ).where(
          "start_working_at BETWEEN ? AND ?",
          Time.now.in_time_zone('America/Santiago').beginning_of_day,
          Time.now.in_time_zone('America/Santiago').end_of_day
        ).order(:start_working_at)

        result = users.map do |user|
          attendances = Attendance.includes(:profile)
            .where(attended_by: user.id, status: [:pending, :processing])
            .order(:created_at)

          {
            user: user,
            profiles: attendances.map do |att|
              profile = att.profile
              {
                id: profile.id,
                name: profile.name,
                email: profile.email,
                birth_date: profile.birth_date,
                phone_number: profile.phone_number,
                organization_id: profile.organization_id,
                branch_id: profile.branch_id,
                attendance_id: att.id,
                status: att.status
              }
            end
          }
        end

        render json: result, status: :ok
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
          :branch_id,
          :attended_by
        )
      end
    end
  end
end
