FactoryGirl.define do
  factory :subscription do
    address_id { FactoryGirl.create(:address).id }
    plan_id { FactoryGirl.create(:plan).id }
    status "active"
    before(:create) do |n|
      address = Address.find(n.address_id)
      n.stripe_customer_id =  address.user.stripe_customer.id
    end
  end
end
