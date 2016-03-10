require 'rails_helper'

RSpec.describe BookingController, :type => :controller do
  it "redirects with error if there is an invalid promo code cookie on checkout" do
    customer = FactoryGirl.create(:stripe_customer)
    FactoryGirl.create(:patient, user_id: customer.user.id )
    customer.user.password = 'testword'
    customer.user.save!

    oncall_time = FactoryGirl.create(
      :oncall_time_with_office_location,
       timerange:(Time.now.
                in_time_zone(
                  'Pacific Time (US & Canada)') - 2.hours)...
                (Time.now.in_time_zone(
                  'Pacific Time (US & Canada)') + 2.hours)) # next_available
    otof = FactoryGirl.create(:oncall_times_office_location, oncall_time_id: oncall_time.id)
    promotion = FactoryGirl.create(:promotion, doctor_id: oncall_time.doctor.id)

    session[:user_id] = customer.user.id

    session[:promo_code] = '234256'
    session[:pv_start] = (Time.now + 40.minutes).to_s
    session[:pv_end] = (Time.now + 65.minutes).to_s
    session[:pv_id] = oncall_time.id.to_s
    session
    session[:pv_office_id] = otof.office_location.id.to_s

    post :create

    expect(response).to redirect_to('/booking')


    expect(flash[:warning]).to eq("We're sorry, the code that was applied to this visit was invalid and has been removed.")

  end
end
