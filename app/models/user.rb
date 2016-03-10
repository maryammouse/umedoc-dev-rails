# == Schema Information
#
# Table name: users
#
#  id                           :integer          not null, primary key
#  firstname                    :string(255)      not null
#  lastname                     :string(255)      not null
#  dob                          :date             not null
#  created_at                   :datetime
#  updated_at                   :datetime
#  gender                       :string(255)      not null
#  username                     :string(255)      not null
#  password_digest              :string(255)      not null
#  authy_id                     :string(255)      not null
#  cellphone                    :string(50)       not null
#  country_code                 :string(5)        default("1"), not null
#  slug                         :text
#  password_reset_token         :string
#  password_reset_sent_at       :datetime
#  email_confirmation           :text             default("not_confirmed"), not null
#  email_confirmation_token     :string
#

class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      record.errors[attribute] << (options[:message] || "is not valid in our system. Sorry about that!")
    end
  end
end


class User < ActiveRecord::Base
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged



  has_many :phones
  has_one :patient
  has_one :doctor
  has_one :stripe_customer
  has_one :stripe_seller
  has_many :addresses
  has_secure_password

  validates :lastname, presence: true, format: { with: /\A[-\w']+\Z/, 
    message: "has characters our system can't handle. We're sorry!"}

  validates :firstname, presence: true, format: { with: /\A[-\w']+\Z/, 
    message: "has characters our system can't handle. We're sorry!"}

  #validates :email, presence: true, email: true

  validates :username, presence: true, email: true,
    uniqueness: true

  validates :password, length: { minimum: 4, :if => :validate_password? },
            format: { with: /\A[-\w']+\Z/, message: "has characters our system can't handle. We're sorry!",
                      if: :validate_password?},
    :confirmation => { :if => :validate_password? }

  validates :dob, presence: true
  validates_date :dob,
    :before => lambda { 18.years.ago },
    :before_message => "must be at least 18 years old"

  validates :gender, presence: true,
    format: { with: /\Amale|female|other\z/, message: 
              "must be male, female, or other" }

  #validates :ssn, allow_blank: true,
    #numericality: { only_integer: true },
    #uniqueness: { message: "We're sorry, that number is already in our system" },
    #length:  { is: 9,
             #allow_blank: true,
             #message: "Must be 9 digits long"}


  #validates :cellnumber,  numericality: { only_integer: true, allow_blank: true}
  #validates :cellnumber,  length: { is: 10,
                                    #allow_blank: true,
                                    #message: "Sorry, the number must be 10 digits long" }
    #
    #
    #

  def generate_token(column)
    begin
      self[column] = SecureRandom.urlsafe_base64
    end while User.exists?(column => self[column])
  end

  def send_password_reset
    generate_token(:password_reset_token)
    self.password_reset_sent_at = Time.zone.now
    save!
    UserMailer.password_reset(self).deliver_now
  end

  def send_signup_emails
    generate_token(:email_confirmation_token)
    save!
    unless self.doctor.present?
      UserMailer.signup_thanks_user(self).deliver_now
      UserMailer.signup_notification_user(self).deliver_now
    else
      UserMailer.signup_thanks_doctor(self).deliver_now
      UserMailer.signup_notification_doctor(self).deliver_now
    end
  end

  def send_confirmation_email
    generate_token(:email_confirmation_token)
    save!
    UserMailer.confirmation_email(self).deliver_now
  end

  protected


    def fullname
      firstname + lastname
    end

    def slug_candidates
      [
      :lastname,
      [:firstname, :lastname],
      [:firstname, :lastname, SecureRandom.hex(3) ],
      ]
    end



  private

    def validate_password?
      password.present? || password_confirmation.present?
    end

end


