# app/services/twilio_message_service.rb
# Servicio para enviar mensajes SMS usando Twilio

require 'twilio-ruby'

class TwilioMessageService
  # Puedes pasar los parámetros o usar Rails.application.credentials
  def initialize
    @client = Twilio::REST::Client.new(account_sid, auth_token)
    @from = from_number
  end


  # Envia un mensaje de WhatsApp usando Twilio
  # to: string (ej: "+56912345678")
  # body: string
  def send_whatsapp(to:, body:)
    @client.messages.create(
      from: "whatsapp:#{@from}",
      to: "whatsapp:#{to}",
      content_sid: 'HX6c76a83f02a4e2cbcc95bdfee3d6b3dd',
      content_variables: { '1' => " #{body[:user_name]}", '2' => body[:profile_name], '3' => body[:organization_name] }.to_json,
      body: body
    )
  end

  private

  def account_sid
    ENV['TWILIO_ACCOUNT_SID'] || Rails.application.credentials.dig(:twilio, :account_sid)
  end

  def auth_token
    ENV['TWILIO_AUTH_TOKEN'] || Rails.application.credentials.dig(:twilio, :auth_token)
  end

  def from_number
    ENV['TWILIO_PHONE_NUMBER'] || Rails.application.credentials.dig(:twilio, :phone_number)
  end
end
