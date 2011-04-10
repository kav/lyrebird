# Create your views here.
import tweepy
from django.http import HttpResponseRedirect, HttpResponseServerError, HttpResponse
from django.shortcuts import redirect, render_to_response


consumer_key = "UgGR2320uaMKFhWDqtm5QQ"
consumer_secret = "Xb1qdKJ8pSFmLXNEf5K8XCH8u0iot4WxUSL7JHUIV4"
callback_url = "http://localhost:8080/"
    

def uber_view(req):
    if 'req_token' in req.session:
        return tw_callback(req)
    elif 'access_key' in req.session:
        return main(req)
    else:
        return twitter_auth(req)
    
def main(req):
    result = models.Retweet.get_by_key_name("k" + req.session['access_key'])
    if result:
        query = result.query
        retweeting = result.query
    else:
        query = "from:kavla"
    return render_to_response("main.html", locals())

def post_test(req):
    auth = tweepy.OAuthHandler(consumer_key,consumer_secret)
    auth.set_access_token(req.session['access_key'], req.session['access_secret'])
    api = tweepy.API(auth)
    api.send_direct_message('kavla', 'nonesense')
    render_to_response("home.html")

def twitter_auth(req):
    
    auth = tweepy.OAuthHandler(consumer_key,consumer_secret, req.build_absolute_uri())
    try:
        url = auth.get_authorization_url()
    except tweepy.TweepError:
        return HttpResponseServerError()
    req.session['req_token'] = (auth.request_token.key,auth.request_token.secret)
    return HttpResponseRedirect(url)

def tw_callback(req):
    auth = tweepy.OAuthHandler(consumer_key,consumer_secret)
    req_token = req.session['req_token']
    del req.session['req_token']
    verifier = req.GET['oauth_verifier']
    auth.set_request_token(req_token[0],req_token[1])
    try:
        auth.get_access_token(verifier)
    except tweepy.TweepError:
        return HttpResponseServerError()
    req.session['access_key'] = auth.access_token.key
    req.session['access_secret'] = auth.access_token.secret    
    return redirect(uber_view)
    
def logout(req):
    del req.session['access_key']
    del req.session['access_secret']
    
from django.utils import simplejson
def setRT(req, query):
    if query:
        addRT(req, query)
    else:
        remRT(req)
    return HttpResponse(simplejson.dumps(query), mimetype="application/json")
    
import models
def addRT(req, searchQuery):
    retweet = models.Retweet(
                access_key = req.session['access_key'],
                access_secret = req.session['access_secret'],
                query = searchQuery)
    retweet.save()
    
def remRT(req):   
    retweet = models.Retweet.get_by_key_name("k" + req.session['access_key'])
    if retweet:
        retweet.delete()
        
        
def retweet(req):
    auth = tweepy.OAuthHandler(consumer_key,consumer_secret)
    for record in models.Retweet.all():
        auth.set_access_token(record.access_key,record.access_secret)
        api = tweepy.API(auth)
        results = tweepy.api.search(record.query)
        for result in results:
            if result.created_at > record.retweeted_at:
                api.retweet(result.id)
        record.save()
        return HttpResponse()