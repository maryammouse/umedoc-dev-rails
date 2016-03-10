class ApplicationController < ActionController::Base
  before_filter :verify_check
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception # TODO UNCOMMENT
  include SessionsHelper
  include DoctorsHelper
  include AuthyHelper
  include SubscriptionHelper
  layout "application"


  def test_exception
    raise 'Testing, 1 2 3.'
  end

  def verify_check
    unless request.path == '/booking' or request.path == '/signup' or
      request.path == '/signup_part2' or
      request.path == '/signup_part3' or
      request.path == '/verify' or request.path == '/users' or
      request.path == '/promotions/redeem' or
      request.path == '/promotions/apply'
      if session[:redirect_to] == '/booking'
        session[:redirect_to] = nil
      end
    end

  end

end
