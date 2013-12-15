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
  
  def welcome
    # @outer_nav = 'o_home'
    @title = 'Welcome'
    respond_to do |format|
      format.html{ render :layout => params[:layout] ? params[:layout] : 'application' }
    end    
  end

  def home
    @homepage_slides = Slide.find_slideshow('homepage')    
    next_event_slide = Event.next_event_slide('homepage')
    last_event_slide = Event.last_event_slide('homepage')
    if last_event_slide
      @homepage_slides.unshift last_event_slide
    end
    if next_event_slide
      @homepage_slides.unshift next_event_slide
    end
    
    @equipment = Equipment.where('user_id is null').order('title').all

    today = DateTime.now.in_time_zone(ENV['TZ'])
    year = params[:year] || today.year
    month = params[:month] || today.month
    @events = Event.for_a_month(year, month)
    
    events = Event.event_types.map{|event_type| event_type.last}
    @next_events = Event.next_events(events, show_on_home = true, events_to_get = 5)
        
    @announcements = Announcement.recents(limit_by = 3)
    
    @comments = Comment.recents(limit_by = 12)

    @outer_nav = 'o_home'
    @title = 'Home'
    respond_to do |format|
      format.html { render :layout => 'home' }
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
