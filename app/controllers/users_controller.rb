require 'mail'
class UsersController < ApplicationController

  before_action :maintenance?
  rescue_from ActionController::InvalidAuthenticityToken, with: :please_enable_cookies

  def new
    @user = User.new
  end

  def signup
  end

  def create
    begin switch_forms; return end if params[:form]
    begin send_reminder; return end if params[:reminder]
    begin guest_signin; return end if params[:user][:name] == ""
    begin register_user; return end if params[:signup]
    registered_user_signin
  end

  def signout
    sign_out
    redirect_to root_path
  end

  def edit
    @user = current_user
    redirect_to root_path form: 'edit'
  end

  def update
    @user = current_user
    if (params[:email])
      begin
        mail_address = Mail::Address.new(params[:email])
      rescue
        flash[:error] = 'Die E-Mail Adresse ist nicht gültig.'
        redirect_to root_path form: 'edit', name: @user.name, email: params[:email]
        return
      end
    end
    if @user.authenticate(params[:oldpassword])
      params[:user][:email_digest] = User.encrypt(params[:email])
      unless @user.update(user_params)
        flash[:error] = @user.errors.messages.values.join('<br />')
        redirect_to root_path form: 'edit', name: @user.name, email: params[:email]
        return
      end
    else
      flash[:error] = "Das alte Kennwort ist falsch."
      redirect_to root_path form: 'edit', name: @user.name, email: params[:email]
      return
    end
    redirect_to root_path
  end

  def User.new_remember_token
    SecureRandom.urlsafe_base64
  end

  def User.encrypt(token)
    Digest::SHA1.hexdigest(token.to_s)
  end

  def please_enable_cookies
    redirect_to please_enable_cookies_path
  end

  def reminder
    if @user = User.find_by(remember_token: params.keys.first)
      if (@user.email_reset_date + 30.minutes) < Time.now
        @user = nil
      end
    end
  end

  def recover
    Rails.logger.error(params)
    if @user = User.find_by(remember_token: params['recover'])
      unless @user.update(user_params)
        flash[:error] = @user.errors.messages.values.join('<br />')
        redirect_back fallback_location: root_path
        return
      end
    end
    sign_in(@user)
    redirect_to root_path
  end

  private

    def create_remember_token
      self.remember_token = User.encrypt(User.new_remember_token)
    end

    def user_params
      params.require(:user).permit(:name, :email_digest, :password, :password_confirmation)
    end

    def switch_forms
      # Anmelden oder Kennwort zurücksetzen wurde angeklickt
      # das entsprechende Formular anzeigen
      @user = User.new(name: params[:name])
      render partial: 'form'
    end

  def send_reminder
    if params[:user][:name] == ''
      flash[:error] = 'Es muss ein Spielername angegeben werden'
    else
      users = User.where(name: params[:user][:name])
      email_digest = User.encrypt(params[:email])
      users.each do |u|
        if u.email_digest == email_digest
          this_reset_date = Time.now
          last_reset_date = u.email_reset_date.nil? ? Time.new : u.email_reset_date
          if (last_reset_date + 1.day) <= this_reset_date
            u.update_column('email_reset_date', this_reset_date)
            UserMailer.with(name: u.name, email: params[:email], remember_token: u.remember_token).reminder_mail.deliver_later
            flash[:success] = "Es wurde eine Nachricht an #{params[:email]} gesandt."
          else
            flash[:error] = "Die E-Mail mit der Kennworterinnerung kann nur einmal pro Tag verschickt werden."
          end
          redirect_to root_path
          return
        end
      end
      flash[:error] = 'Es muss die E-Mail Adresse angegeben werden, die beim Anlegen des Spielers verwendet wurde.'
    end
    redirect_to root_path form: 'reminder', name: params[:user][:name], email: params[:email]
  end

  def guest_signin
    pwd = User.new_remember_token
    @user = User.new(name: 'Gast', password: pwd, password_confirmation: pwd, guest: 1)
    @user.save(validate: false)
    sign_in(@user)
    redirect_to root_path
  end

  def registered_user_signin
    users = User.where(name: params[:user][:name])
    users.each do |u|
      if u.authenticate(params[:password])
        sign_in(u)
        redirect_to root_path
        return
      end
    end
    flash[:error] = 'Name oder Kennwort falsch. Bitte Groß- und Kleinschreibung beachten.'
    redirect_to root_path form: 'signup', name: params[:user][:name], email: params[:email]
  end

  def register_user
    params[:user][:email_digest] = User.encrypt(params[:email])
    @user = User.new(user_params)
    if @user.save
      sign_in(@user)
      redirect_to root_path
      return
    else
      flash[:error] = @user.errors.messages.values.join('<br />')
    end
    redirect_to root_path form: 'signup', name: params[:user][:name], email: params[:email]
  end

end
