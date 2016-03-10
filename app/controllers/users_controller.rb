class UsersController < ApplicationController
  def show
    @user = User.friendly.find(params[:id])
    unless @user.doctor
      raise ActionController::RoutingError.new('Not Found')
    end

    @doctor = Doctor.find_by(user_id: @user.id)
    unless @doctor.nil?
      @credentials = MedicalLicense.find_by(doctor_id: @doctor.id)
      if @credentials.nil?
        @credentials = TemporaryCredential.find_by(doctor_id: @doctor.id)
      end
    end


  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.username = session[:username]
    @user.cellphone = session[:cellphone]
    @user.authy_id = session[:authy_id]
    if @user.save
      log_in @user
      if session[:license_number]
        @new_doc = Doctor.new(user_id: @user.id)
        if @new_doc.save
          temp_creds = TemporaryCredential.new(license_number: session[:license_number],
                                              state_medical_board_id: session[:state_medical_board_id],
                                              is_general_practice: session[:is_general_practice],
                                              specialty_opt1: session[:specialty_opt1],
                                              specialty_opt2: session[:specialty_opt2],
                                              doctor_id: @new_doc.id )
          unless temp_creds.save
            flash[:error] = "We're sorry, your credentials didn't save. That shouldn't happen! [let us know]"
            logger.info( " THESE WERE THE ERRORS " + temp_creds.errors.messages.to_s
                       )
            return
          end
            session[:license_number] = nil
            session[:state_medical_board_id] = nil
            session[:is_general_practice] = nil
            session[:specialty_opt1] = nil
            session[:specialty_opt2] = nil
        end

      else
        @user.slug = @user.id
        @user.save
        @new_patient = Patient.new(user_id: @user.id)
        unless @new_patient.save
          flash[:error] = "There was an error in creating your account. We're sorry! Please let us know [here]!"
          redirect_to('/signup_part3') and return
        end


      end
      session[:username] = nil
      session[:cellphone] = nil
      session[:authy_id] = nil
      flash[:success] = "Your account has been created. Welcome to Umedoc! We've sent you a confirmation email."
      SendSignupEmailsJob.perform_later(@user) if @user

      whitelist = []
      if @user.doctor
        redirect_to '/' + @user.slug
      else
        if session[:redirect_to] == '/booking'
          redirect_to('/booking')
        else
          redirect_to('/landing/thankyou')
        end
      end


    else
      render 'new'
    end
  end

  def confirm_email
    user = User.find_by_email_confirmation_token!(params[:id])
    if user.update_attribute(:email_confirmation, 'confirmed')
      redirect_to root_url, notice: "Your email has been confirmed!"
    end
  end

  private

    def user_params
      params.require(:user).permit(:firstname, :lastname, :username, :password, :password_confirmation, :dob, :gender)
    end
end
