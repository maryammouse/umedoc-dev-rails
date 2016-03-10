FactoryGirl.define do
  factory :plan do
    stripe_seller_id { FactoryGirl.create(:stripe_seller).id }
    plan_id "sds"
    fee 6000
    before(:create) do |n|
      stripe_seller = StripeSeller.find(n.stripe_seller_id)
      plan_list = Stripe::Plan.all({}, stripe_seller.access_token)
      unless plan_list.first.nil?
        preplan = Stripe::Plan.retrieve("sds", stripe_seller.access_token)
        preplan.delete
      end
    end
  end
end
