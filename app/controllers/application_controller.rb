class ApplicationController < ActionController::API
  attr_reader :current_user
  ACTIONS_TO_FILTER = %w[index today].freeze
  before_action :apply_filters, if: -> { ACTIONS_TO_FILTER.include?('index') }

  private

  def authorize_request
    header = request.headers['Authorization']
    token = header.split(' ').last if header.present?

    begin
      Rails.logger.info "Authorizing token: #{token}"
      Rails.logger.info "Key base: #{Rails.application.credentials.secret_key_base}"
      decoded = JWT.decode(token, Rails.application.credentials.secret_key_base)[0]
      raise JWT::ExpiredSignature if Time.at(decoded["exp"]) < Time.now

      @current_user = User.find(decoded["user_id"])
    rescue ActiveRecord::RecordNotFound, JWT::DecodeError, JWT::ExpiredSignature
      render json: { error: 'Unauthorized or token expired' }, status: :unauthorized
    end
  end

  def apply_filters
    if controller_name.classify.safe_constantize&.respond_to?(:filter_by_params)
      @filtered_records = controller_name.classify.safe_constantize.filter_by_params(params)
    end
  end
end
