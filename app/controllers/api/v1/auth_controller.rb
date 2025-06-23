module Api
  module V1
    class AuthController < ApplicationController
      before_action :authorize_request, only: [:me]
      def login
        user = User.find_by(email: params[:email])

        if user&.authenticate(params[:password])
          token = encode_token({
            user_id: user.id,
            exp: Time.now.in_time_zone('America/Santiago').end_of_day.to_i
          })
          render json: { token: token, user: user }, status: :ok
        else
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end

      def me
        render json: @current_user.as_json(include: { role: {} })
      end

      private

      def encode_token(payload)
        JWT.encode(payload, Rails.application.credentials.secret_key_base)
      end
    end
  end
end
