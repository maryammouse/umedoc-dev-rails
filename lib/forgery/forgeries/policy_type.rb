class Forgery::PolicyType < Forgery
  def self.policy_type
    dictionaries[:policy_types].random.unextend
  end
end
