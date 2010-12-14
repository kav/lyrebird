from appengine_django.models import BaseModel
from google.appengine.ext import db

# Create your models here.
# class Retweet(BaseModel):
class Retweet(BaseModel):
    #TODO: Consider refactoring so key_name is returned directly
    query = db.StringProperty()
    retweeted_at = db.DateTimeProperty(auto_now=True)
    access_key = db.StringProperty()
    access_secret = db.StringProperty()
    def __init__(self, *args, **kwargs):
        if 'access_key' in kwargs:
            kwargs['key_name'] = "k" + kwargs['access_key']
            kwargs['key'] = None
        super(Retweet, self).__init__(*args, **kwargs)
        
        
        
