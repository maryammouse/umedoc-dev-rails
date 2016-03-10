require 'rails_helper'

describe OnlineVisitsController, :type => :controller, focus:true do
  it "allows logged in users to visit page" do
    patient = FactoryGirl.create(:patient)
    doctor = FactoryGirl.create(:doctor)

    session[:user_id] = patient.user.id

    get :show

    expect(response).not_to redirect_to login_url
  end
end

#  it "redirects visitors who are not logged in" do
    #session[:user_id] = nil

    #get :show
    
    #expect(response).to redirect_to login_url
  #end

#end
