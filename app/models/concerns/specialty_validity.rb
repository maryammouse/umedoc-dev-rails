module SpecialtyValidity
  extend ActiveSupport::Concern
  def valid_specialty?(specialty)
    unless Specialty.find_by(name: specialty).nil?
      true
    else
      false
    end
  end
end
