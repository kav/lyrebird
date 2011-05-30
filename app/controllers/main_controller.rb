require 'json'
require 'cgi'

class MainController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:ipn]

  def get_consumer
    return OAuth::Consumer.new(
      'UgGR2320uaMKFhWDqtm5QQ',
      'Xb1qdKJ8pSFmLXNEf5K8XCH8u0iot4WxUSL7JHUIV4',
      {:site => 'http://twitter.com'}
    )
  end

  def signin
    if session.has_key?("user")
      redirect_to :action => "search"
      return
    end    
    consumer = get_consumer()
    request_token = consumer.get_request_token(:oauth_callback => url_for(:controller => "main", :action => "authorize"))
    session['request_token'] = request_token
    redirect_to request_token.authorize_url
  end
  
  def authorize
    if not session.has_key?("request_token")
      redirect_to :action => "signin"
      return
    end
    request_token = session['request_token']
    access_token = request_token.get_access_token
    json = access_token.get("https://api.twitter.com/1/account/verify_credentials.json")
    userinfo = JSON.parse(json.body)
    user = User.find_or_create_by_name(userinfo["screen_name"])
    user.access_token = access_token.token
    user.access_secret = access_token.secret
    user.save!
    session['user'] = userinfo["screen_name"]
    redirect_to :action => "search"
  end
  
  def search
    if not session.has_key?("user")
      redirect_to :action => "signin"
      return
    end
    @user = User.find_by_name(session['user'])
    
    # if the user existed before we took money give them
    # a trial starting 6/1
    if not @user.paid
      payments_start = "June 1 2011".to_date

      if @user.created_at.to_date < payments_start then
        trial_start = payments_start
      else
        trial_start = @user.created_at.to_date
      end

      trial_ends = trial_start + 14.days
      @days_remaining = (trial_ends - Date.today).to_i
      if @days_remaining < 0
        @trial_over = true
        @days_remaining = 0
      end
    end
    
    respond_to do |format|
    	format.html
    end	
  end
  
  # Search management
  def add
    @success = false
    @user = User.find_by_name(params[:user])
    search_text = params[:search]
    
    if !search_text.blank? && !@user.searches.find_by_text(search_text) then 
      @search = @user.searches.create(:text => search_text)      
      @success = @search.valid?
      set_last_tweet(@search)
    end

    respond_to do |format|
      format.json
    end
  end
  
  def remove
    @success = false
    @user = User.find_by_name(params[:user])
    search_id = params[:search_id]
    @search = @user.searches.find_by_id(search_id)
    if @search then
      @search.destroy
      @success = true
    end
    
    respond_to do |format|
      format.json
    end
  end
  
  
  def logout
    reset_session
    redirect_to "/"
  end
  
  def remove_account
    if session.has_key?("user")
      user = User.find_by_name(session['user'])
      User.delete(user)
    end
    logout
  end
  
  
  def retweet
    consumer = get_consumer()
    User.all.each do |user|
      access_token = OAuth::AccessToken.new(consumer, user.access_token, user.access_secret)

      user.searches.each do |search|
        #get tweets
        query_string = "https://search.twitter.com/search.json?q=#{CGI.escape(user.search)}&since_id=#{user.last_tweet}"
        json = access_token.get(query_string)
        results = JSON.parse(json.body)

        if results.has_key?("results") then
          results["results"].each do |tweet|
            #retweet each, should like add some logging here for response.code not in the 200 series
            access_token.post("https://api.twitter.com/1/statuses/retweet/#{tweet["id"]}.json")
            search.last_tweet = tweet["id"] if tweet["id"] > search.last_tweet
          end
        end

        search.save
      end
    end
  end
  
  def ipn
    @raw = request.raw_post
    uri = URI.parse("https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_notify-validate")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    response = http.request_post(uri.request_uri, @raw, 'Content-Length' => "#{@raw.size}")
    
    if response.body != "VERIFIED" then
      logger.error "Body: #{response.body}"
      logger.error "Url: #{request.fullpath}"
      logger.error "Raw post: #{@raw}"
    else
      @user = User.find(params[:user_id])
      logger.info "Ready to process payments for user #{@user.id}"

      #subscr_cancel - Subscription canceled
      # do nothing
      
      #subscr_eot - Subscription expired
      # remove permission
      
      #subscr_failed - Subscription signup failed
      # send nice "you need some help" message
      
      #subscr_modify - Subscription modified
      # error - send mail to admins
      
      #subscr_payment - Subscription payment received
      # do nothing
      
      #subscr_signup - Subscription started
      # add permission
      
      #user.active?
      #user.last_paid
      
      # TODO: 
      # Check the payment_status is Completed 
      # Check that txn_id has not been previously processed 
      # Check that receiver_email is your Primary PayPal email 
      # Check that payment_amount/payment_currency are correct 
      # Process payment 
    end
  end
  
  #todo: move to model event code path for changes to search
  def set_last_tweet(search)
    access_token = OAuth::AccessToken.new(get_consumer(), search.user.access_token,
      search.user.access_secret)
      
    query_string = "https://search.twitter.com/search.json?q=#{CGI.escape(search.text)}&rpp=1"
    json = access_token.get(query_string)
    results = JSON.parse(json.body)
    
    if results.has_key?("results") && results["results"].count > 0
      search.last_tweet = results["results"][0]["id_str"]
    else
      search.last_tweet = "1"
    end
    
    search.save
  end
end
