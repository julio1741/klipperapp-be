class ApplicationController < ActionController::API
  attr_reader :current_user

  private

  def authorize_request
    header = request.headers['Authorization']
    token = header.split(' ').last if header.present?

    begin
      decoded = JWT.decode(token, Rails.application.credentials.secret_key_base)[0]
      raise JWT::ExpiredSignature if Time.at(decoded["exp"]) < Time.now

      @current_user = User.find(decoded["user_id"])
    rescue ActiveRecord::RecordNotFound, JWT::DecodeError, JWT::ExpiredSignature
      render json: { error: 'Unauthorized or token expired' }, status: :unauthorized
    end
  end
end
