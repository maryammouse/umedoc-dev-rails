class DoctorsController < ApplicationController
  autocomplete :medical_school, :name, :full => true
  autocomplete :state_medical_board, :name, :full => true
  autocomplete :specialty, :name, :full => true

  def new
    @temporary_credential = TemporaryCredential.new
    @doctor = Doctor.new
  end

  def create
    temp_cred = params[:temporary_credential]


    if valid_credentials?(temp_cred)
      session[:state_medical_board_id] = StateMedicalBoard.find_by(name: temp_cred[:state_medical_board_id]).id
      session[:license_number] = temp_cred[:license_number]
      session[:is_general_practice] = temp_cred[:is_general_practice]
      if temp_cred[:specialty_opt1] = ""
        temp_cred[:specialty_opt1] = "None"
      end
      if temp_cred[:specialty_opt2] = ""
        temp_cred[:specialty_opt2] = "None"
      end
      session[:specialty_opt1] = temp_cred[:specialty_opt1]
      session[:specialty_opt2] = temp_cred[:specialty_opt2]
      flash[:info] = "Sign up to continue!"
      redirect_to('/signup')
    else
      render 'new'
    end
  end

  private

    def user_params
      params.require(:temporary_credential).permit(:awarded_by, :license_number, :is_general_practice, :specialty_opt1, :specialty_opt2)
    end
end
