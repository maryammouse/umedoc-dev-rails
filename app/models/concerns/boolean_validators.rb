module BooleanValidators
  extend ActiveSupport::Concern
  
  def both_false?(val1, val2)
    if val1 == false and val2 == false
      return true
    else
      return false
    end
  end

  # I don't think this is useful..GMS 02/22/2015
  def boolean?(thing)
    if !!thing == thing
      true
    else
      false
    end
  end
end
