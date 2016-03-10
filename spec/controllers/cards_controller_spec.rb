require 'rails_helper'

RSpec.describe CardsController, :type => :controller do

  describe 'When someone tries to update with a bad zipcode' do
    it 'redirects to the cards page' do
      post "update", :card => {:zipcode => '2814825665'}

      expect(response).to redirect_to('/cards')
    end
  end
end
