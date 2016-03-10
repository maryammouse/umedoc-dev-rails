class ChatEntriesController < ApplicationController
  include ERB::Util
  def latest
    @chat_entry = ChatEntry.where(connectionid: params[:connectionid]).last

    render :json => @chat_entry
  end

  def add
    @chat_entry = ChatEntry.new
    @chat_entry.connectionid = params[:connectionid]
    @chat_entry.body = html_escape(params[:body])
    @chat_entry.session_id = session[:visit_session_id]
    @chat_entry.name = current_user.firstname + ' ' + current_user.lastname

    @chat_entry.save

    render :json => @chat_entry
  end
end
