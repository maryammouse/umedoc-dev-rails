module AuthyHelper
  def valid_temp_user?(temp_user)
    @temporary_user = User.new
    if unique_username?(temp_user[:username]) and
      unique_cellphone?(temp_user[:cellphone])
      true
    else
      if unique_username?(temp_user[:username]) == false
        @temporary_user.errors.add(:username,  "is already taken")
      end
      if unique_cellphone?(temp_user[:cellphone]) == false
        @temporary_user.errors.add(:cellphone, "is already registered with Umedoc")
      end
      if temp_user[:username] == ''
        @temporary_user.errors.add(:username, "can't be blank")
      end
      if temp_user[:cellphone] == ''
        @temporary_user.errors.add(:cellphone, "can't be blank")
      end
      false
    end
  end

  def unique_username?(username)
    if User.find_by(username: username).nil?
      true
    else
      false
    end
  end

  def unique_cellphone?(cellphone)
    if User.find_by(cellphone: cellphone).nil?
      true
    else
      false
    end
  end
end
