class UnsubscribeMailController < ApplicationController
  def index
  end

  def destroy
    mail_list_item = MailingList.find_by(email: unsubscribe_params[:email])

    if mail_list_item
      mail_list_item.destroy
      flash[:success] = 'You have successfully unsubscribed. Please let us know if you have any further problems!'
    end

    redirect_to('/')

  end

  private

    def unsubscribe_params
      params.require(:unsubscribe).permit(:email)
    end
end
