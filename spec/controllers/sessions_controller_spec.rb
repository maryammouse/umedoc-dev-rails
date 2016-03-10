require 'rails_helper'

describe SessionsController, type: :controller, focus:true do
  it "creates user_id in cookie on create/login" do
    user = FactoryGirl.create(:user)
    patient = FactoryGirl.create(:patient, user_id: user.id)

    post :create, session: { username: user.username, password: user.password }

    expect(session[:user_id]).not_to equal nil
  end
end
