class Forgery::Degree < Forgery
  def self.medical_degree
    dictionaries[:medical_degrees].random.unextend
  end
end
