require 'rails_helper'

RSpec.describe LandingController, :type => :controller do

=begin  describe 'When someone tries to access the thankyou page without the right session variable' do
    it 'redirects to the home page' do
      get "thanks"

      expect(response).to redirect_to('/')
    end
  end
=end

=begin
  describe 'When someone tries to access the thankyou page with the right session variable' do
    it 'renders the thankyou page' do
      session[:campaign] = 'day'
      get "thanks"

      expect(response).to render_template("thanks")

      session[:campaign] = 'night'
      get "thanks"

      expect(response).to render_template("thanks")
    end
  end
=end
end
