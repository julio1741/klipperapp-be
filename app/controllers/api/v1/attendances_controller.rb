module Api
  module V1
    class AttendancesController < ApplicationController
      before_action :authorize_request
      before_action :set_attendance, only: [:show, :update, :destroy]

      # GET /api/v1/attendances
      def index
        @attendances = (@filtered_records || Attendance.includes(:attended_by_user, :profile, :service))
          .where(status: [:pending, :processing, :completed, :finished, :canceled, :postponed])
          .order(:created_at)

        render json: @attendances.map { |attendance|
          attendance.as_json(include: {
            attended_by_user: {},
            profile: {},
            services: [],
            child_attendances: []
          })
        }
      end

      # GET /api/v1/attendances/today
      def today
        today = Time.now.in_time_zone('America/Santiago').beginning_of_day
        @attendances = (@filtered_records || Attendance.includes(:attended_by_user, :profile, :service))
          .where(status: [:pending, :processing, :completed, :finished, :canceled, :postponed])
          .where("created_at >= ?", today)
          .order(Arel.sql("CASE status
            WHEN 'pending' THEN 1
            WHEN 'processing' THEN 2
            WHEN 'postponed' THEN 3
            WHEN 'completed' THEN 4
            WHEN 'finished' THEN 5
            WHEN 'canceled' THEN 6
            ELSE 6 END, id ASC"))
        render json: @attendances.map { |attendance|
          attendance.as_json(include: {
            attended_by_user: {},
            profile: {},
            services: [],
            child_attendances: []
          })
        }
      end

      # GET /api/v1/attendances/history
      def history
        yesterday = Time.now.in_time_zone('America/Santiago').beginning_of_day
        sort = params[:sort] || 'created_at'
        dir = params[:dir] || 'desc'
        @attendances = (@filtered_records || Attendance.includes(:attended_by_user, :profile, :service))
          .where(status: [:completed, :finished, :canceled])
          .where("created_at <= ?", yesterday)
          .order("#{sort} #{dir}")
        render json: @attendances.map { |attendance|
          attendance.as_json(include: {
            attended_by_user: {},
            profile: {},
            services: [],
            child_attendances: []
          })
        }
      end

      # GET /api/v1/attendances/:id
      def show
        render json: @attendance, serializer: AttendanceSerializer, include: ['attended_by_user', 'profile', 'services', 'child_attendances', 'child_attendances.attended_by_user', 'child_attendances.profile', 'child_attendances.services']
      end

      # POST /api/v1/attendances
      def create
        @attendance = Attendance.new(attendance_params)
        if @attendance.save
          @attendance.services = Service.where(id: params[:service_ids]) if params[:service_ids].present?
          @attendance.child_attendances << Attendance.where(id: params[:child_attendance_ids]) if params[:child_attendance_ids].present?
          @attendance.send_message_to_frontend
          render json: @attendance.as_json(include: {
          attended_by_user: {},
          profile: {},
          services: [],
          child_attendances: []
        }), status: :ok
        else
          render json: @attendance.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/attendances/:id
      def update
        if @attendance.update(attendance_params)
          @attendance.services = Service.where(id: params[:service_ids]) if params[:service_ids].present?
          @attendance.child_attendances << Attendance.where(id: params[:child_attendance_ids]) if params[:child_attendance_ids].present?
          render json: @attendance.as_json(include: {
          attended_by_user: {},
          profile: {},
          services: [],
          child_attendances: []
        }), status: :ok
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
        result = UserQueueService.new(
          organization_id: organization_id,
          branch_id: branch_id,
          role_name: 'agent'
        ).queue.select { |user| ['available', 'not_available', 'working'].include?(user.work_state) }

        # select users without attendances pending today
        result = result.select do |user|
          Attendance.pending_attendances_today_by_user(user.id).empty?
        end

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
            .where(attended_by: user.id, status: [:pending, :processing, :postponed])
            .order(Arel.sql("CASE status WHEN 'processing' THEN 1 WHEN 'postponed' THEN 2 WHEN 'pending' THEN 3 END, created_at ASC"))

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
                status: att.status,
                clickeable: att.clickeable?
              }
            end
          }
        end

        render json: result, status: :ok
      end

      def statistics
        year = params[:year]
        month = params[:month]
        day = params[:day]
        organization_id = params[:organization_id]
        branch_id = params[:branch_id]
        user_id = params[:user_id]

        stats = Statistics.new(year: year,
          month: month,
          day: day,
          organization_id: organization_id,
          branch_id: branch_id,
          user_id: user_id
        ).perform

        render json: stats, status: :ok
      end

      # GET /api/v1/attendances/summary
      def summary
        start_day = params[:start_day]
        end_day = params[:end_day]
        organization_id = params[:organization_id]
        branch_id = params[:branch_id]
        user_id = params[:user_id]
        status = params[:status]

        summary = AttendanceSummary.new(
          start_day: start_day,
          end_day: end_day,
          organization_id: organization_id,
          branch_id: branch_id,
          user_id: user_id,
          status: status
        ).perform

        render json: summary, status: :ok
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
          :organization_id,
          :branch_id,
          :attended_by,
          :discount,
          :extra_discount,
          :user_amount,
          :organization_amount,
          :start_attendance_at,
          :end_attendance_at,
          service_ids: []
        )
      end
    end
  end
end
