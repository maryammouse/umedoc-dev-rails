module PromotionsHelper
  include ActionView::Helpers::NumberHelper

  def promotion_name(promotion)
    if promotion.name
      promotion.name
    else
      discount_name_determination(promotion.discount_type, promotion.discount)
    end
  end

  def discount_name_determination(discount_type, discount)
    if discount_type == 'percentage'
      discount.to_s + '% off!'
    elsif discount_type == 'fixed'
      number_to_currency(discount) + ' off!'
    end
  end

  def discount_description(discount_type, discount)
    if discount_type == 'percentage'
      discount.to_s + '%'
    elsif discount_type == 'fixed'
      number_to_currency(discount)
    end
  end

end
