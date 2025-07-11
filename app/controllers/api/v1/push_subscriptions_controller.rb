module Api
  module V1
    class PushSubscriptionsController < ApplicationController
      before_action :authorize_request

      def create
        subscription = @current_user.push_subscriptions.find_or_initialize_by(subscription_data: subscription_params.to_h)

        if subscription.save
          render json: { message: "Subscription saved." }, status: :created
        else
          render json: { errors: subscription.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        subscription = @current_user.push_subscriptions.find_by("subscription_data->>'endpoint' = ?", params[:endpoint])

        if subscription
          subscription.destroy
          render json: { message: "Subscription removed." }, status: :ok
        else
          render json: { error: "Subscription not found." }, status: :not_found
        end
      end

      private

      def subscription_params
        params.require(:subscription).permit(:endpoint, keys: [:p256dh, :auth])
      end
    end
  end
end
