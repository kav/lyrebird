require 'json'
class MainController < ApplicationController
  def signin
#    if session.has_key?("user")
#      redirect_to :action => "search"
#      return
#    end
    
    consumer = OAuth::Consumer.new(
      'UgGR2320uaMKFhWDqtm5QQ',
      'Xb1qdKJ8pSFmLXNEf5K8XCH8u0iot4WxUSL7JHUIV4',
      {:site => 'http://twitter.com'}
    )
    request_token = consumer.get_request_token(:oauth_callback => 'http://localhost:3000/authorize')
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
    user.search = ""
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
    set_last_tweet(@user) if @user.search != ""
    respond_to do |format|
      format.js
    end
  end
  def logout
    user = User.find_by_name(session['user'])
    User.delete(user)
    reset_session
    redirect_to "/"
  end
  
  def retweet
    consumer = OAuth::Consumer.new(
      'UgGR2320uaMKFhWDqtm5QQ',
      'Xb1qdKJ8pSFmLXNEf5K8XCH8u0iot4WxUSL7JHUIV4',
      {:site => 'http://twitter.com'}
    )
    
    User.all.each do |user|
      if user.search != ""
        access_token = OAuth::AccessToken.new(consumer, user.access_token, user.access_secret)
        #get tweets
        query_string = "https://search.twitter.com/search.json?q=" + user.search + "&since_id=" + user.last_tweet.to_s()
        json = access_token.get("https://search.twitter.com/search.json?q=")
        results = JSON.parse(json.body)
        results["results"].each do |tweet|
          #retweet each
          access_token.post("https://api.twitter.com/1/statuses/retweet/" + tweet["id"].to_s())
          user.last_tweet = tweet["id"] if tweet["id"] > user.last_tweet
        end
        user.save!
      end
    end
  end
  
  def set_last_tweet(user)
    consumer = OAuth::Consumer.new(
      'UgGR2320uaMKFhWDqtm5QQ',
      'Xb1qdKJ8pSFmLXNEf5K8XCH8u0iot4WxUSL7JHUIV4',
      {:site => 'http://twitter.com'}
    )
    access_token = OAuth::AccessToken.new(consumer, user.access_token, user.access_secret)
    query_string = "https://search.twitter.com/search.json?q=" + user.search + "&rpp=1"
    json = access_token.get(query_string)
    results = JSON.parse(json.body)
    user.last_tweet = results["results"][0]["id"]
    puts user.last_tweet
    user.save
  end
end
