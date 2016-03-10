class Plan < ActiveRecord::Base
  before_save :stripe_plan

  belongs_to :stripe_seller
  has_many :subscription

  def stripe_plan
    begin
      plan = Stripe::Plan.create(
          {
              :amount => fee,
              :interval => 'month',
              :name => 'Simple Doctor Service',
              :currency => 'usd',
              :id => 'sds'
          },
          stripe_seller.access_token
      )


      rescue => e
        errors.add(:plan_id, e.message)
        return false
    end


  end
end
