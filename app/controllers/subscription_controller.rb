class SubscriptionController < ApplicationController
  protect_from_forgery :except => :webhook

  def index
  end

  def edit
    unless current_user && current_user.patient && current_user.stripe_customer && current_user.stripe_customer.subscription
      flash[:warning] = 'Only patients with subscriptions may access that page.'
      redirect_to('/') and return
    end
    @plan = current_user.stripe_customer.subscription.plan
    @stripe_plan = Stripe::Plan.retrieve("sds", @plan.stripe_seller.access_token)

    @customer = @current_user.stripe_customer
    if @customer
      @stripe_customer = Stripe::Customer.retrieve(@customer.customer_id)
      if @stripe_customer.default_source
        @card = @stripe_customer.sources.retrieve(@stripe_customer.default_source)
      end
    end
  end

  def update
  end

  def new
    # debugging helper
    # session[:plan] = {"id" => "sds", "doctor_key" => "sk_test_hLSr46i6XVmC7MM7Y6v55nrw"}
    unless session[:plan].present?
      flash[:warning] = "You haven't chosen a plan to subscribe to!"
      redirect_to('/') and return
    end
    @plan = Stripe::Plan.retrieve(session[:plan]["id"], session[:plan]["doctor_key"])
    # Stripe::Plan.retrieve("doctorsplan", 'sk_test_UBU41fIJLzcf9nGaAymge3hQ')
    if logged_in?
      @customer = @current_user.stripe_customer
      if @customer
        @stripe_customer = Stripe::Customer.retrieve(@customer.customer_id)
        if @stripe_customer.default_source
          @card = @stripe_customer.sources.retrieve(@stripe_customer.default_source)
        end
      end
    end
  end

  def create
    @stripe_plan = Stripe::Plan.retrieve(session[:plan]["id"], session[:plan]["doctor_key"])
    ss = StripeSeller.find_by(access_token: session[:plan]["doctor_key"])
    @plan = ss.plan

    token_id = subscription_params[:stripeToken]

    if current_user.stripe_customer.nil?
      begin

        @stripe_customer = Stripe::Customer.create(
            {
                :source => token_id,
                :description => current_user.username
            }
        )


        StripeCustomer.create(user_id: current_user.id, customer_id: @stripe_customer.id)

      rescue => e
        flash[:warning] = e
        redirect_to '/booking'
      end
    end


    customer = Stripe::Customer.retrieve(StripeCustomer.find_by(user_id: current_user.id).customer_id)

    unless subscription_params[:stripe][:address].nil?
      address = Address.find_by(id: subscription_params[:stripe][:address].to_s)
    else
      mailing_name = current_user.firstname + ' ' + current_user.lastname
      address =  Address.new(street_address_1: subscription_params[:stripe][:street_address_1],
                             street_address_2: subscription_params[:stripe][:street_address_2],
                             city: subscription_params[:stripe][:city],
                             state: subscription_params[:stripe][:state],
                             zip_code: subscription_params[:stripe][:zip_code],
                             mailing_name: mailing_name,
                             user_id: current_user.id)
    end

    if address.save
      subscription = Subscription.new(stripe_customer_id: current_user.stripe_customer.id,
                                      plan_id: @plan.id, address_id: address.id


      )

      subscription.save
    end



    if subscription.errors.count > 0 or address.errors.count > 0
      flash[:warning] = "There are some errors"
      subscription.errors.full_messages.each do |msg|
        flash[:warning] << "<br> " + msg + "<br>"
      end
      address.errors.full_messages.each do |msg|
        flash[:warning] << "<br> " + msg + "<br>"
      end
      redirect_to('/subscribe/new') and return
    end

    flash[:success] = 'You have been subscribed to the ' + @stripe_plan.name +
        '. An email receipt has been sent to your address'
    redirect_to('/subscribe/edit')


  end

  def webhook
    begin
      event_json = JSON.parse(request.body.read)
      event_object = event_json['data']['object']
      #refer event types here https://stripe.com/docs/api#event_types
      unless Rails.env.test?
        event = Stripe::Event.retrieve(event_json["id"])
      end
      if (event and (StripeEvent.find_by(event_id: event.id).nil?)) or Rails.env.test?
        if event
          StripeEvent.create!(event_id: event.id)
        end
        case event_json['type']
          when 'invoice.payment_succeeded'
            handle_success_invoice event_object
          when 'invoice.payment_failed'
            handle_failure_invoice event_object
          when 'customer.subscription.deleted'
            handle_deleted_subscription event_object
          when 'customer.subscription.updated'
            handle_subscription_update event_object
        end
      end
    rescue Exception => ex
      render :json => {:status => 422, :error => ex.to_s }
      return
    end
    render :json => {:status => 200}
  end

  def mail

    email = MailingList.new(email: mail_params[:email], campaign: 'Umedoc You')
    if email.save
      SendUpdateJob.perform_later(email) if email
      flash[:success] = "You are now part of the mailing list! Thanks for joining. We'll keep the emails to a minimum but we will let you
know when Umedoc You is up and running! You should recieve an email to confirm this."
    else
      email.errors.full_messages.each do |msg|
        flash[:warning] = msg
        flash[:warning] << "<br> Please try again."
        redirect_to('/subscribe') and return
      end
    end

    redirect_to('/subscribe')
  end



  private

    def subscription_params
      params.permit({ stripe: [:street_address_1, :street_address_2, :city,
                    :state, :zip_code, :address] },
                    :stripeToken)
    end

  def mail_params
    params.permit(:email)
  end

end
