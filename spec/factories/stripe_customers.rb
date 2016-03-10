# == Schema Information
#
# Table name: stripe_customers
#
#  id          :integer          not null, primary key
#  customer_id :string(255)      not null
#  user_id     :integer          not null
#

FactoryGirl.define do
  Stripe.api_key =  "sk_test_dKGEciDlQdQrqHZKtZyRnlV6" #
  factory :stripe_customer do
    association :user
    #user_id { FactoryGirl.create(:user).id }
    customer_id { (Stripe::Customer.create()).id }

    factory :stripe_customer_with_card do
      after(:create) do |n|
        cus = Stripe::Customer.retrieve(n.customer_id)
        cus.sources.create(card: { object: 'card', number: '4242424242424242',
                            exp_month: 05,
                            exp_year: rand(2016..2020),
                            cvc: 593,
                            address_zip: '94025'

        })
      end
    end

    factory :bad_stripe_customer_with_card do
      after(:create) do |n|
        cus = Stripe::Customer.retrieve(n.customer_id)
        cus.sources.create(card: { object: 'card', number: '4000000000000341',
                                   exp_month: 05,
                                   exp_year: rand(2016..2020),
                                   cvc: 593,
                                   address_zip: '94025'
                           })
      end
    end

    end
end
