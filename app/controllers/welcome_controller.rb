  class WelcomeController < ApplicationController
    def index
      @lead_time = 30.minutes
      @duration = 30.minutes
      @available = FreeTime.all_available(lead_time: @lead_time, duration: @duration )
      @cheapest_online_query = FreeTime.available_times.where(online_visit_allowed: 'allowed')
      @cheapest_office_query = FreeTime.available_times.where(office_visit_allowed: 'allowed')
      @cheapest_online_list = []
      @cheapest_office_list = []
      @cheapest_online_query.each do |n|
        if n.oncall_time.online_locations.present?
          @cheapest_online_list << n
        end
      end
      @cheapest_office_query.each do |n|
        if n.oncall_time.office_locations.present?
          @cheapest_office_list << n
        end
      end

      @cheapest_online = @cheapest_online_list.min_by {|ft| ft.online_visit_fee }
      @cheapest_office = @cheapest_office_list.min_by {|ft| ft.office_visit_fee }

      @start_time = (Time.now + @lead_time).round_off 5.minutes # TODO: Remove
      @end_time = (@start_time + @duration).round_off 5.minutes
      if logged_in? && current_user.patient
        @added = current_user.patient.patients_promotions.order(id: :asc)
        if @added.present?
          @selected_promo = Promotion.find_by(promo_code: session[:promo_code]) || @added.first.promotion
          session[:promo_code] = @selected_promo.promo_code
        end
      end
  end

  def temporary_visit
    if current_user
      if current_user.doctor.nil?
        session[:pv_start] = params[:start]
        session[:pv_end] = params[:end]
        session[:pv_id] = params[:ot_id]
        session[:pv_office_id] = params[:office_id]
        redirect_to('/booking')
      else
        flash[:warning] = "Doctor accounts cannot book appointments!"
        redirect_to('/')
      end
    else
      session[:pv_start] = params[:start]
      session[:pv_end] = params[:end]
      session[:pv_id] = params[:ot_id]
      session[:pv_office_id] = params[:office_id]
      redirect_to('/booking')
    end
  end

    def apply
      code = promotion_apply_params[:promo_code]
      promo = Promotion.find_by(promo_code: code)
      @oncall_time = OncallTime.find_by(id: session[:pv_id].to_i)

      if Promotion.currently_bookable?(current_user, code, nil)
        session[:promo_code] = promo.promo_code
        flash[:success] = 'Your code was successfully applied!'
      else
        flash[:danger] = 'That coupon cannot be used! It has either been used up or expired.
      Please try another.'
      end
      redirect_to('/')
    end

    private

      def promotion_apply_params
        params.permit(:promo_code)
      end
end
