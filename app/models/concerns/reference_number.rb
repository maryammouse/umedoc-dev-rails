module ReferenceNumber
  extend ActiveSupport::Concern

  def valid_dea?(dea_number)
  
    if dea_number.nil?
      false
      return
    end

    if dea_number.length != 9
      false
    end

    valid_letter1 = "ABFG"
    valid_letter2 = "A".."Z"
    valid_numbers = 0..9
    test_number = dea_number
    
    unless valid_letter1.include? dea_number[0]
      false
    end
    unless valid_letter2.include? dea_number[1]
      false
    end

    check_digit = dea_number[2].to_i + dea_number[4].to_i + dea_number[6].to_i
    check_digit += (dea_number[3].to_i + dea_number[5].to_i + dea_number[7].to_i) * 2

    if dea_number[-1] == check_digit.to_s[-1]
      true
    else
      false
    end
  end

  def valid_npi?(npi_number)

    if npi_number.nil? or npi_number.length != 10
      return false
    end

    unless "12".include?(npi_number[0])
      return  false
    end

    answer = npi_number[0,9]


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

    if npi_number[-1].to_i == check_digit
      return true
    else
      return false
    end

  end

end
