from tweepy.streaming import StreamListener
from tweepy import OAuthHandler
from tweepy import Stream

import sys
import tweepy
import time

# Go to http://apps.twitter.com and create an app.
# The consumer key and secret will be generated for you after
consumer_key="SRnN2WpjXhk0yfJ7AdVSfcSYs"
consumer_secret="Arvv0EbCvAnbEL5PaaffvZphdylqcAkCTDGTnVprBljEkLz5lS"

# After the step above, you will be redirected to your app's page.
# Create an access token under the the "Your access token" section
access_token="15967313-VsNsXbx9K777wYYxzyZvxY5RosqWcRNGdqWcHuOey"
access_token_secret="6gXuPyC6pPKEybrbDwHhA3X5RkuHgsvLEICj8ATRCpZLG"

class StdOutListener(StreamListener):
    """ A listener handles tweets are the received from the stream.
    This is a basic listener that just prints received tweets to stdout.

    """
    def on_data(self, data):
        print data
        return True

    def on_error(self, status):
        print status

if __name__ == '__main__':
    l = StdOutListener()
    auth = OAuthHandler(consumer_key, consumer_secret)
    auth.set_access_token(access_token, access_token_secret)

    track_trends = []
    while True:
        try:
            api = tweepy.API(auth)
            global_trends = api.trends_place(id=1).pop()

            track_trends = []
            for trend in global_trends['trends']:
                track_trends.append(trend['name'])

            if len(track_trends) == 0:
                sys.stderr.write(time.strftime("%Y-%m-%d %H:%M:%S") + " got 0 trends, retrying\n")
                continue

            break
        except tweepy.error.TweepError as e:
            sys.stderr.write(time.strftime("%Y-%m-%d %H:%M:%S") + " error getting trends: " + str(e) + ", retrying\n")

    stream = Stream(auth, l)
    stream.filter(track=track_trends)
