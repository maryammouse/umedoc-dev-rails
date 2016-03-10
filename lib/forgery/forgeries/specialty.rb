class Forgery::Specialty < Forgery

  def self.specialty
    dictionaries[:specialties].random.unextend
  end
end
