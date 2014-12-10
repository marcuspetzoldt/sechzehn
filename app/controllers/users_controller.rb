class UsersController < ApplicationController

  before_action :maintenance?

  def new
    @user = User.new
  end

  def signup

  end

  def create
    if params[:guest_signup]
      pwd = User.new_remember_token
      @user = User.new(name: 'Gast', password: pwd, password_confirmation: pwd, guest: 1)
      @user.save(validate: false)
      sign_in(@user)
    else
      if params[:signup]
        params[:user][:password] = params[:password]
        params[:user][:password_confirmation] = params[:password]
        @user = User.new(user_params)
        if @user.save
          sign_in(@user)
        else
          flash[:error] = @user.errors.messages.values.join('<br />')
        end
      else
        users = User.where(name: params[:user][:name])
        users.each do |u|
          if u.authenticate(params[:password])
            sign_in(u)
            redirect_to root_path
            return
          end
        end
        @user = User.new(user_params)
        flash[:error] = 'Name oder Kennwort falsch. Bitte Groß- und Kleinschreibung beachten.'
      end
    end
    redirect_to root_path
  end

  def signout
    sign_out
    redirect_to root_path
  end

  def edit
    @user = current_user
    redirect_to root_path what: 'edit'
  end

  def update
    @user = current_user
    if @user.authenticate(params[:password])
      params[:user][:password_confirmation] = params[:user][:password]
      unless @user.update(user_params)
        flash[:error] = @user.errors.messages.values.join('<br />')
        redirect_to root_path what: 'edit'
        return
      end
    else
      flash[:error] = 'Das Kennwort ist falsch.'
      redirect_to root_path what: 'edit'
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

  private

    def create_remember_token
      self.remember_token = User.encrypt(User.new_remember_token)
    end

    def user_params
      params.require(:user).permit(:name, :password, :password_confirmation)
    end

end
