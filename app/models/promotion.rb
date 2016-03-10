# == Schema Information
#
# Table name: promotions
#
#  discount             :integer          not null
#  max_uses_per_patient :integer          not null
#  name                 :string(255)
#  promo_code           :string(255)      not null
#  id                   :integer          not null, primary key
#  timezone             :text             default("Pacific Time (US & Canada)"), not null
#  doctor_id            :integer          not null
#  applicable_timerange :tstzrange        not null
#  bookable_timerange   :tstzrange        not null
#  applicable           :text             not null
#  bookable             :text             not null
#  discount_type        :text             not null
#

class Promotion < ActiveRecord::Base
  extend ActionView::Helpers::NumberHelper
  extend TimerangeValidators
  extend ColumnConsistencyValidators

  belongs_to :doctor
  has_many :patients_promotions
  has_many :patients, through: :patients_promotions

  validates :name, allow_blank: true, format: { with: /\A[0-9]*[-\w'\s]+\Z/,
    message: "has characters our system can't handle. We're sorry!"}

  validates :promo_code, presence: true, length: { is: 6}

  validates :promo_code, presence: true, format: { with: /\A[-\w']+\Z/,
    message: "has invalid characters"}

  validates :discount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :discount_type, presence: true, format: { with: /\Apercentage|fixed\Z/, 
  message: "must be percentage or fixed" }
  validate :discount_and_type_validity

  validates :timezone, presence: true,
    format: { with: /\A[-\w'\s()&]+\Z/, message:
              "has invalid characters" }

  validates :applicable, presence: true, format: { with: /\Aapplicable|not_applicable\Z/,
    message: "must be applicable or not_applicable"}

  validates :bookable, presence: true, format: { with: /\Abookable|not_bookable\Z/,
    message: "must be bookable or not_bookable"}

  validates :max_uses_per_patient, presence: true, numericality: { only_integer: true }

  validates :applicable_timerange, presence: true
  validates :bookable_timerange, presence: true
  validate :applicable_timerange_validity
  validate :bookable_timerange_validity

  validates :doctor_id, presence: true

  def applicable_timerange_validity
    unless Promotion.start_before_end?(applicable_timerange)
      error_msg = "ends before it starts, which is impossible (unless you're a time traveler.) Please try again!"
      errors.add(:applicable_timerange, error_msg)
    end
  end
  def bookable_timerange_validity
    unless Promotion.start_before_end?(bookable_timerange)
      error_msg = "either ends on the current day or in the past,
      which is impossible (unless you're a time traveler.) Please try again!"
      errors.add(:bookable_timerange, error_msg)
    end
  end
  def discount_and_type_validity
    unless Promotion.consistent_discount_columns?(discount_type, discount)
      error_msg = "The discount value is invalid for that type of discount"
      errors.add(:base, error_msg)
    end
  end



  def self.currently_bookable?(user, promo_code, doctor)
    promo = Promotion.find_by(promo_code: promo_code)
    current_user = User.find_by(id: user.id)
    if promo
      if promo.bookable == 'bookable' and (doctor.nil? || (promo.doctor == doctor)) and
          ((not current_user.patient.patients_promotions.find_by(promotion_id: promo.id).nil?) &&
              (current_user.patient.patients_promotions.find_by(promotion_id: promo.id).uses_counter <
                  promo.max_uses_per_patient)) and
          promo.bookable_timerange.cover?(Time.now)
        true
      else
        false
      end
    else
       false
    end
  end

  def self.currently_applicable?(user, promo_code)
    promo = Promotion.find_by(promo_code: promo_code)
    current_user = user
    if promo
      if promo.applicable == 'applicable' and
          current_user.patient.patients_promotions.find_by(promotion_id: promo.id).nil? and
          promo.applicable_timerange.cover?(Time.now)
        true
      else
        false
      end
    else
      false
    end
  end

  def self.discounted_fee(promotion, fee)
    discount_type = promotion.discount_type
    discount = promotion.discount

    if discount_type == 'fixed'
      calc = fee - discount
    elsif discount_type == 'percentage'
      calc = fee.to_f - (fee.to_f * (discount / 100.0).to_f) # DO NOT EVER MAKE THE 100 A NON FLOAT!!
    end

    if calc <= 0
      number_to_currency(0)
    else
     number_to_currency(calc)
    end

  end

  def self.free_visit?(promotion, fee)
    discount_type = promotion.discount_type
    discount = promotion.discount

    if discount_type == 'fixed'
      calc = fee - discount
    elsif discount_type == 'percentage'
      calc = fee.to_f - (fee.to_f * (discount / 100).to_f)
    end

    if calc <= 0
      true
    else
      false
    end
  end

end
