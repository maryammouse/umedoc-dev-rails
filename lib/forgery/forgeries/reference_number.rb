class Forgery::ReferenceNumber < Forgery
  def self.dea_number
    letter1 = "ABFG"
    letter2 = "A".."Z"
    numbers = 0..9
    answer = ""
    answer << letter1[rand(4)]
    answer << letter2.to_a.join[rand(26)]
    6.times { |i| answer << numbers.to_a.join[rand(10)] }
    check_digit = answer[2].to_i + answer[4].to_i + answer[6].to_i
    check_digit += (answer[3].to_i + answer[5].to_i + answer[7].to_i) * 2
    answer << check_digit.to_s[-1]
    return answer
  end

  def self.npi_number

    # You can read more about the steps as described by cms at
    # https://www.cms.gov/Regulations-and-Guidance/HIPAA-Administrative-Simplification/
    # (url continued here!) NationalProvIdentStand/downloads/NPIcheckdigit.pdf

    first_number =1..2
    numbers = 0..9
    answer = ""

    answer << first_number.to_a.join[rand(2)]
    8.times { |i| answer << numbers.to_a.join[rand(10)] }

    # Step One

    double_neg1 = answer[-1].to_i * 2
    double_neg3 = answer[-3].to_i * 2
    double_neg5 = answer[-5].to_i * 2
    double_neg7 = answer[-7].to_i * 2
    double_neg9 = answer[-9].to_i * 2

    # Step Two

    doubled = [double_neg1, double_neg3, double_neg5,
              double_neg7, double_neg9]

    split_doubles_add = []

    doubled.each do |i|
      i.to_s.split('').each { |j| split_doubles_add << j.to_i }
    end

    double_neg2 = answer[-2].to_i
    double_neg4 = answer[-4].to_i
    double_neg6 = answer[-6].to_i
    double_neg8 = answer[-8].to_i

    all_but_doubles = 24 + double_neg2 + double_neg4 + double_neg6 + double_neg8

    everything = all_but_doubles + split_doubles_add.inject(:+)
    
    # Step Three

    ceiling = (everything/10.0).ceil * 10

    check_digit = ceiling - everything

    answer << check_digit.to_s
    answer
  end
end
