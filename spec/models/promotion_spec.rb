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

require 'rails_helper'

describe "Promotion" do
  describe "Promotion is valid with:" do

      it "is valid with a discount, discount_type, max_uses_per_patient, applicable_timerange, bookable_timerange,
      applicable, bookable, name, promo_code, timezone, doctor_id" do
        promotion = build(:promotion)
        promotion.valid?
        expect(promotion).to be_valid
      end

  end

  describe "Promotion is invalid without: " do

    fields = %i{ discount discount_type max_uses_per_patient applicable bookable applicable_timerange bookable_timerange
    promo_code timezone doctor_id }
    fields.each do |field|
      it "is invalid if #{ field } is nil" do
        promotion = build(:promotion,
                    field => nil)
        promotion.valid?
        expect(promotion.errors[field]).to include("can't be blank")
      end
    end
  end

  describe "Promotion is invalid with incorrect: " do

    test_array =  [
               ['discount',  '-1',       'must be greater than 0'],
               ['max_uses_per_patient',  'jfasjgiawjgiawgj', "is not a number"],
               ['applicable',                'faswagwag', "must be applicable or not_applicable"],
               ['bookable',                'faswagwag', "must be bookable or not_bookable"],
               ['name',                  'sup@ promot!on woo)', "has characters our system can't handle. We're sorry!"],
               ['promo_code',            '1f3a1s321412faa', 'is the wrong length (should be 6 characters)'],
               ['promo_code',            '4h1s', 'is the wrong length (should be 6 characters)'],
               ['promo_code',            '4%dha@^', 'has invalid characters'],
               ['timezone',              'P@c!f!c T1!me (US & C@nada)',  'has invalid characters'],
    ]


    test_array.each do |field_name, field_value, field_error|
        it "is invalid with incorrect #{ field_name }: #{ field_value } " do
          promotion = build(:promotion,
                      field_name => field_value)
          promotion.valid?
          expect(promotion.errors[field_name]).to include(field_error)
      end
    end
  end

  describe "timeranges" do
    it "applicable_timerange is invalid if start is after end" do
      promotion = build(:promotion,
                   applicable_timerange: (Time.now + 6.hours)..(Time.now + 2.hours))
      promotion.valid?
      expect(promotion.errors[:applicable_timerange]).to include("ends before it starts, which is impossible (unless you're a time traveler.) Please try again!")
    end

    it "bookable_timerange is invalid if start is after end" do
      promotion = build(:promotion,
                   bookable_timerange: (Time.now + 6.hours)..(Time.now + 2.hours))
      promotion.valid?
      error_msg = "either ends on the current day or in the past,
      which is impossible (unless you're a time traveler.) Please try again!"
      expect(promotion.errors[:bookable_timerange]).to include(error_msg)
    end
  end

  describe "discounts" do
    it "Gives an error if discount_type is percentage and discount is an invalid percentage" do
      promotion = build(:promotion,
                       discount_type: 'percentage',
                       discount: '123')
      promotion.valid?
      expect(promotion.errors[:base]).to include("The discount value is invalid for that type of discount")

    end

    it "returns a fee of 0 if the discount amount is 100 and type is percentage" do
      promotion = create(:promotion,
                       discount_type: 'percentage',
                       discount: '100')
      fee_after_discount = Promotion.discounted_fee(promotion, 100)
      expect(fee_after_discount).to eq("$0.00")
    end
  end

  describe Promotion do
    it { should belong_to(:doctor) }
    it { should have_many(:patients).through(:patients_promotions) }
  end
end
