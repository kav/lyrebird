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
    respond_to do |format|
    	format.html
    end	
  end
  
  def save
    @user = User.find_by_name(params[:user])
    @user.search = params[:search]
    @user.save!
    set_last_tweet(@user) if not @user.search.blank?
    respond_to do |format|
      format.js
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
      if not user.search.blank?
        access_token = OAuth::AccessToken.new(consumer, user.access_token, user.access_secret)
        #get tweets
        query_string = "https://search.twitter.com/search.json?q=#{CGI.escape(user.search)}&since_id=#{user.last_tweet}"
        json = access_token.get(query_string)
        results = JSON.parse(json.body)

        if results.has_key?("results")
          results["results"].each do |tweet|
            #retweet each, should like add some logging here for response.code not in the 200 series
            access_token.post("https://api.twitter.com/1/statuses/retweet/#{tweet["id"]}.json")
            user.last_tweet = tweet["id"] if tweet["id"] > user.last_tweet
          end
        end

        user.save!
      end
    end
  end
  
  def ipn
    @raw = request.raw_post
    uri = URI.parse("http://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_notifyvalidate")
    http = Net::HTTP.new(uri.host, uri.port)
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.use_ssl = true
    response = http.request_post(uri.request_uri, @raw)
      
    if response.body != "VERIFIED" then
      logger.error "Body: #{response.body}"
      logger.error "Url: #{request.fullpath}"
      logger.error "Raw post: #{@raw}"
    else
      @user = User.find(params[:user_id])
      logger.info "Ready to process payments for user #{@user.id}"
    end
  end
  
  #todo: move to model event code path for changes to search
  def set_last_tweet(user)
    return if user.search.blank?
    
    consumer = get_consumer()
    access_token = OAuth::AccessToken.new(consumer, user.access_token, user.access_secret)
    query_string = "https://search.twitter.com/search.json?q=#{CGI.escape(user.search)}&rpp=1"
    json = access_token.get(query_string)
    results = JSON.parse(json.body)
    
    if results.has_key?("results") && results["results"].count > 0
      user.last_tweet = results["results"][0]["id"]
    else
      user.last_tweet = 1
    end
    
    user.save!
  end
end
