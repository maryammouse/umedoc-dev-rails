class CardsController < ApplicationController
  def new
    unless logged_in? and current_user.patient
      flash[:warning] = "We're sorry, only logged in patients can access that page."
      redirect_to('/')
      return
    end


    @customer = StripeCustomer.find_by(user_id: current_user.id)
    if @customer
      @stripe_customer = Stripe::Customer.retrieve(@customer.customer_id)
      if @stripe_customer.default_source
        @card = @stripe_customer.sources.retrieve(@stripe_customer.default_source)
      end
      @cards = @stripe_customer.sources
    end
  end

  def update
    token = card_update_params # params[:card]
    if ZipCode.find_by(zip: token[:zipcode]).nil?
      flash[:warning] = "That is not a valid zipcode in our database. Sorry!"
      redirect_to('/cards')
      return
    end
    @customer = StripeCustomer.find_by(user_id: current_user.id)
    unless @customer
      flash[:info] = "You need to be logged in to change card details."
      redirect_to('/')
      return
    end

    @stripe_customer = Stripe::Customer.retrieve(@customer.customer_id)
    card = @stripe_customer.sources.retrieve(@stripe_customer.default_source)
    card.address_zip = token[:zipcode]
    card.exp_month = token["exp_month(2i)"]
    card.exp_year = token["exp_year(1i)"]
    if card.save
      flash[:success] = 'Your information for the card ending in ' + card.last4 + ' has been updated!'
      redirect_to('/cards')
    end

    rescue Stripe::CardError => e
      flash[:warning] = e.to_s
      redirect_to('/cards') and return

  end

  def create
    token = card_create_params

    @customer = StripeCustomer.find_by(user_id: current_user.id)
    unless @customer
      flash[:info] = "You need to make one purchase before adding a card."
      redirect_to('/')
      return
    end

    @stripe_customer = Stripe::Customer.retrieve(@customer.customer_id)
    begin
    @stripe_customer.sources.create(source: { object: 'card', 
                  number: token[:number],
                  address_zip: token[:zipcode],
                  exp_month: token["exp_month(2i)"],
                  exp_year: token["exp_year(1i)"],
                  cvc: token[:cvc]
    })


    rescue Stripe::CardError => e
      puts " WITHIN RESCUE "
      flash[:warning] = e.to_s
      redirect_to('/cards') and return

    end


    duplicates = {}
    @stripe_customer = Stripe::Customer.retrieve(@customer.customer_id)
    @stripe_customer.sources.each do |n|
      if duplicates[n.fingerprint].nil?
        duplicates[n.fingerprint] = [n.id]
      else
        duplicates[n.fingerprint] << n.id
      end
    end

    pending_deletion = []
    duplicates.each do |key, value|
      if duplicates[key].count > 1
        pending_deletion << duplicates[key].pop
      end
    end

    pending_deletion.each do |n|
      @stripe_customer.sources.retrieve(n).delete
    end




    if pending_deletion.empty?
    flash[:success] = "Your card has successfully been added!"
    else
      flash[:warning] = "That card has already been added!"
    end
    redirect_to('/cards')
  end

  def select
    token = card_select_params
    puts "This is the token"
    puts token

    @customer = StripeCustomer.find_by(user_id: current_user.id)
    unless @customer
      flash[:info] = "You need to be logged in to add a card."
      redirect_to('/')
      return
    end

    @stripe_customer = Stripe::Customer.retrieve(@customer.customer_id)

    source_list = []
    @stripe_customer.sources.each do |n|
      if n.last4 == token[:selected]
        source_list << n.id
      end
    end

    if source_list.count == 1
      @stripe_customer.default_source = source_list.first
      @stripe_customer.save
    else
      flash[:error] = 'There are duplicate cards in our system. That should not happen! '
    end


    redirect_to('/cards')
  end

  def delete
    @customer = StripeCustomer.find_by(user_id: current_user.id)
    unless @customer
      flash[:info] = "You need to be logged in to delete card details."
      redirect_to('/')
      return
    end

    @stripe_customer = Stripe::Customer.retrieve(@customer.customer_id)
    @stripe_customer.sources.retrieve(@stripe_customer.default_source).delete

    redirect_to('/cards')

  end

  private

    def card_update_params
      params.require(:card).permit(:zipcode, :exp_month, :exp_year,)
    end

    def card_create_params
      params.require(:card).permit(:number, :zipcode, :exp_month, :exp_year, :cvc)
    end

    def card_select_params
      params.require(:card).permit(:selected)
    end


end
