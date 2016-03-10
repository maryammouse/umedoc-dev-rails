class StripeSellerController < ApplicationController
  require 'httparty'

  def new
      @code = params[:code]
      @result = HTTParty.post("https://connect.stripe.com/oauth/token",
                              query: {  client_secret: ENV['STRIPE_SK'] ,
                               code: @code,
                               grant_type: 'authorization_code'
    })
      logger.info("THIS IS THE RESULT" + @result.to_s)

      if @result["access_token"]
        StripeSeller.create( user_id: current_user.id,
                            access_token: @result["access_token"],
                            scope: @result["scope"],
                            livemode: @result["livemode"].to_s,
                            refresh_token: @result["refresh_token"],
                            stripe_user_id: @result["stripe_user_id"],
                            stripe_publishable_key: @result["stripe_publishable_key"]
                           )
      else
        @error =  " There was an error! Please try again. "
      end
  end
end
