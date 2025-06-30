class UserMailer < ApplicationMailer
  def email_verification(user)
    @user = user
    mail(to: @user.email, subject: 'Verifica tu correo electrónico')
  end
end
