class Forgery::PhoneType < Forgery
  def self.phone_type
    dictionaries[:phone_types].random.unextend
  end
end
