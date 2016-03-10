module TimerangeValidators
  extend ActiveSupport::Concern
  def start_before_end?(timerange)
    if timerange.nil?
      return false
    end

    unless timerange.begin < timerange.end
      false
    else
      true
    end
  end
end
