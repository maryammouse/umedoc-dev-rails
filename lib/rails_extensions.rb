# http://stackoverflow.com/questions/677034/adding-a-method-to-built-in-class-in-rails-app


# http://stackoverflow.com/questions/18774943/rounding-a-rails-datetime-to-the-nearest-15-minute-interval
#class DateTime

  #def round(granularity=1.hour)
    #Time.at((self.to_time.to_i/granularity).round * granularity).to_datetime
  #end

#end

#http://stackoverflow.com/questions/449271/how-to-round-a-time-down-to-the-nearest-15-minutes-in-ruby 
require 'active_support/core_ext/numeric' # from gem 'activesupport'

class Time
  # Time#round already exists with different meaning in Ruby 1.9
  def round_off(seconds = 60)
    Time.at((self.to_f / seconds).round * seconds)
  end

  def floor(seconds = 60)
    Time.at((self.to_f / seconds).floor * seconds)
  end
end
