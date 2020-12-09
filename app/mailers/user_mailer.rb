class UserMailer < ApplicationMailer
  def reminder_mail
    @user = params[:name]
    @url = "https://spiele.sechzehn.org/reminder?#{params[:remember_token]}"
    mail(to: params[:email], subject: 'sechzehn.org: Kennwort vergessen')
  end
end
