class Forgery::Boolean < Forgery

  def self.boolean
    dictionaries[:booleans].random.unextend
  end
end
