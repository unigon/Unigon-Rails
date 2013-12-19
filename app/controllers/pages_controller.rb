# coding: utf-8
class PagesController < ApplicationController

  def error
    flash[:notice] = 'An error occurred; we are unable to find the page you are looking for.'

    respond_to do |format|
      format.html { render :layout => 'home' }
    end    
  end
  
  def non_secure_for_not_signed_in_users
    if !current_user && request.ssl?
      redirect_to non_secure_root_url
      return
    end
  end
  
  def home
    # @outer_nav = 'o_home'
    @title = 'Welcome'
    respond_to do |format|
      format.html{ render :layout => params[:layout] ? params[:layout] : 'application' }
    end    
  end
  
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  def contact
    @iloveastronomy = 'I like astronomy.'
    @outer_nav = 'o_about_us'
    @title = 'Contact Us'
    @user = current_user
    @user ||= User.new
    passes_captcha = current_user ? true : ( params[:recaptcha_response_field] && validate_recap(params, @user.errors) )
    passes_iloveastronomy = current_user ? true : (params[:iloveastronomy] && params[:iloveastronomy] == @iloveastronomy)
    if params[:message] && params[:subject] && params[:role_name] && passes_captcha && passes_iloveastronomy
      if current_user
        email_from = current_user.email 
        name_from  = current_user.display
      else
        email_from = params[:email]
        name_from  = params[:name]
      end
      
      role_to = params[:role_name]
      users_with_role = []
      users_with_role = Role.find_by_name(params[:role_name]).users.map{ |user| user.email }
      users_with_role = users_with_role.empty? ? Role.find_by_name('webmaster').users.map{ |user| user.email } : users_with_role
  
      GenericMailer.contact_role(request.host, email_from, name_from, role_to, users_with_role.join(', '), params[:subject], params[:message]).deliver      
      redirect_to root_url, :notice => "Thanks, #{params[:name]}! We will get back to you soon."
      return
    elsif params[:mode] == 'submit'
      unless passes_iloveastronomy
        @user.errors.add(:prove_you_are_human, "You forgot to tell us what you like.")
      end
      
      flash[:notice] = 'Please fill in all fields.'
    else
      # unless passes_iloveastronomy
      #   @user.errors.add(:prove_you_are_human, "You forgot to tell us what you like.")
      # end      
    end
    respond_to do |format|
      format.html { render :layout => 'application' }
    end 
  end

end
