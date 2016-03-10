module StateValidity
  extend ActiveSupport::Concern

  def is_state?(valid_in)
    unless State.find_by(iso: valid_in).nil?
      true
    else
      false
    end
  end
end
