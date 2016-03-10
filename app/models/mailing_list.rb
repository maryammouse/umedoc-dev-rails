class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      record.errors[attribute] << (options[:message] || "is not valid in our system. Sorry about that!")
    end
  end
end

class MailingList < ActiveRecord::Base

  validates :email, presence: true, email: true

  validates :campaign, presence: true

  validates_uniqueness_of :email, scope: :campaign,
                          message: "has already been used to sign up for updates for this campaign."


  def send_update
    UpdateMailer.confirm_update(self).deliver_now
  end
end
