class PushNotificationJob < ApplicationJob
  queue_as :default

  def perform(user_id, title, body)
    user = User.find_by(id: user_id)
    return unless user

    payload = JSON.generate(title: title, body: body)

    user.push_subscriptions.each do |subscription|
      WebPush.payload_send(
        message: payload,
        endpoint: subscription.subscription_data['endpoint'],
        p256dh: subscription.subscription_data['keys']['p256dh'],
        auth: subscription.subscription_data['keys']['auth'],
        vapid: {
          subject: 'mailto:support@klipperapp.com',
          public_key: ENV['VAPID_PUBLIC_KEY'],
          private_key: ENV['VAPID_PRIVATE_KEY']
        }
      )
    rescue WebPush::InvalidSubscription => e
      # The subscription is no longer valid, maybe the user unsubscribed.
      # It's a good idea to delete it from the database.
      puts "Deleting invalid subscription for user #{user.id}: #{e.message}"
      subscription.destroy
    rescue => e
      # Log other errors without stopping the loop
      puts "Error sending push notification to user #{user.id}: #{e.message}"
    end
  end
end
