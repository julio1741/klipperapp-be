class UserMailer < ApplicationMailer
  def email_verification(user)
    @user = user
    mail(to: @user.email, subject: 'Verifica tu correo electrónico')
  end

  def reset_verification_code(user)
    @user = user
    mail(to: @user.email, subject: 'Nuevo código de verificación de correo')
  end
end
