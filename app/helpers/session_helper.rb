module SessionHelper

  def sign_in(user)
    if user.guest
      session[:remember_token] = user.id
    else
      remember_token = User.new_remember_token
      cookies.permanent[:remember_token] = { value: remember_token, domain: :all }
      user.update_attribute(:remember_token, User.encrypt(remember_token))
    end
    self.current_user = user
  end

  def sign_out
    if current_user.guest
      session[:remember_token] = nil
    else
      current_user.update_attribute(:remember_token, User.encrypt(User.new_remember_token))
      cookies.delete(:remember_token, domain: :all)
    end
    self.current_user = nil
  end

  def current_user=(user)
    @current_user = user
  end

  def current_user
    if session[:remember_token]
      @current_user ||= User.find_by(id: session['remember_token'])
    else
      @current_user ||= User.find_by(remember_token: User.encrypt(cookies[:remember_token]))
    end
  end

  def signed_in?
    !current_user.nil?
  end

  def registered_user?
    current_user ? current_user.guest.nil? : false
  end

 end