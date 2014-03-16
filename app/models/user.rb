class User < ActiveRecord::Base

  before_create :create_remember_token
  has_many :guesses
  has_many :scores
  has_secure_password

  validates :name, presence: true, length: { minimum: 3, maximum: 32 }
  validates :password, length: { minimum: 6 }

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

end
