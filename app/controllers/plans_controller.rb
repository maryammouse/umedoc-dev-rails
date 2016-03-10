class PlansController < ApplicationController
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::OutputSafetyHelper

  def index
  end

  def new
    if current_user
      unless current_user.doctor
        flash[:warning] = 'Only doctors can join and offer the Simple Doctor Service.
                          If you wish to subscribe, you can do so here.'
        redirect_to('/subscribe/index') and return
      end
    end
  end

  def create
    @doctor = current_user.doctor


    begin
      plan = Plan.new(fee: (plan_params[:amount].to_i * 100),
      stripe_seller_id: current_user.stripe_seller.id,
      plan_id: "sds")

      plan.save

    rescue => e
      flash[:danger] = e.message
      redirect_to('/sds/join') and return
    end


    if plan.errors.count == 0
      flash[:success] = 'You are now a part of the Simple Doctor Service!'
    else
      flash[:warning] = "<div align='center'>The plan could not
       be created.<br> It contains " + pluralize(plan.errors.count, "error") + "!<br><br></div>"
      plan.errors.full_messages.each do |msg|
        flash[:warning] << "<li>" + msg + "</li>"
      end
      redirect_to('/sds/join') and return
    end

    redirect_to('/sds/subscribers')

  end

  def subscribers
    customers = Stripe::Customer.all({}, current_user.stripe_seller.access_token)
    subscribers = []
    customers.each do |c|
       c.subscriptions.each do |s|
         subscription = c.subscriptions.retrieve(s.id)
         if subscription.plan.id == "sds"
           subscribers << c
         end
       end
    end
  end

  private

  def plan_params
    params.require(:plan).permit(:amount)
  end
end
