class AuthyController < ApplicationController
  def new
    if current_user
      redirect_to('/')
    else
      @temporary_user = User.new
    end
  end

  def create
    temporary_user = params[:temporary_user]


    if valid_temp_user?(temporary_user)
      session[:username] = temporary_user[:username]

      phone_info = Authy::PhoneIntelligence.info(
        :country_code => "#{temporary_user[:country_code]}",
        :phone_number => "#{temporary_user[:cellphone]}"
      )


      unless phone_info["type"] == "cellphone"
        flash[:warning] = "That is not a valid cellphone number."
        redirect_to('/signup')
        return
      end

      session[:country_code] = temporary_user[:country_code]
      session[:cellphone] = temporary_user[:cellphone]

      authy = Authy::API.register_user(:email => session[:username], :cellphone => session[:cellphone],
                                       :country_code => session[:country_code])
      if authy.ok?
        session[:authy_id] = authy.id
        result = Authy::API.request_sms(:id => session[:authy_id],
                                       :force => true )
      else
        flash[:warning] = "Email " + authy.errors["email"]
        redirect_to('/signup')
        return
      end

      redirect_to('/signup_part2')

    else
      render 'new'
    end

  end

  def part2
  end

  def part2_verify
    if current_user
      redirect_to('/')
    end
    verification = params[:verification]
    answer = Authy::API.verify(:id => session[:authy_id], :token => verification[:token])

    if answer.ok?
      redirect_to '/signup_part3'
    else
      flash[:warning] = "The code was invalid. Please re-enter it or request a new one."
      redirect_to '/signup_part2'
    end
  end

  def part2_resend
    if current_user
      redirect_to('/')
    end
    Authy::API.request_sms(:id => session[:authy_id],
                           :force => true )
    flash[:info] = "Your code has been resent!"
    render 'part2'
  end
end
