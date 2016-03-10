require "opentok"
OT_KEY = ENV['OT_KEY']
OT_SECRET = ENV['OT_SECRET']
OPENTOK = OpenTok::OpenTok.new OT_KEY, OT_SECRET
Stripe.api_key = ENV['STRIPE_SK']
