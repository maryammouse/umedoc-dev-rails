module ColumnConsistencyValidators
  extend ActiveSupport::Concern

  def consistent_discount_columns?(discount_type, discount)
    if discount_type.nil? or discount.nil?
      false
      return
    end 

    if discount_type == 'percentage'
      if discount <= 100 and discount > 0
        true
      else
        false
      end
    else
      true
    end
  end

end
