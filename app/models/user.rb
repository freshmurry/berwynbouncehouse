class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, 
         :confirmable, :omniauthable
         
  validates :fullname, presence: true, length: {maximum: 50}
  
  has_many :barbershops
  has_many :reservations
  
  has_many :client_reviews, class_name: "ClientReview", foreign_key: "client_id"
  has_many :barber_reviews, class_name: "BarberReview", foreign_key: "barber_id"
  has_many :notifications
  
  has_one :setting
  after_create :add_setting

  def add_setting
    Setting.create(user: self, enable_sms: true, enable_email: true)
  end
    
  def self.from_omniauth(auth)
    user = User.where(email: auth.info.email).first
  
    if user
      return user
    else
      where(provider: auth.provider, uid: auth.uid).first_or_create do |u|
       user.email = auth.info.email
       user.password = Devise.friendly_token[0,20]
       user.fullname = auth.info.name
       user.image = auth.info.image
       user.uid = auth.uid
       user.provider = auth.provider
    
       # If you are using confirmable and the provider(s) you use validate emails,
       # uncomment the line below to skip the confirmation emails.
       user.skip_confirmation!
      end
    end
  end

  def generate_pin
    self.pin = SecureRandom.hex(2)
    self.phone_verified = false
    save
  end
  
  def send_pin
    @client = Twilio::REST::Client.new
    @client.messages.create(
      from: '+3125488878',
      to: self.phone_number,
      body: "Your pin is #{self.pin}"
    )
  end

  def verify_pin(entered_pin)
    update(phone_verified: true) if self.pin == entered_pin
  end

  def is_active_barber
    !self.merchant_id.blank?
  end

end


# Strict password security measures. *Uncomment when app goes live!*
  # validates :password, :presence => true,
  #                   :on => :create,
  #                   :format => {:with => /\A.*(?=.{8,})(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[\!\@\#\$\%\^\&\+\=]).*\Z/ }