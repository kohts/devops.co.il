import web

import pymongo
from pymongo import MongoClient
from pprint import pprint

urls = (
    '/(.*)', 'hello',
)
app = web.application(urls, globals())

class hello:
    def GET(self, name):
        client = MongoClient()
        db = client['devopscoil']
        twi_msg = db['twitter.messages']

        usernames = []

        for msg in twi_msg.find():
            if 'entities' in msg.keys() and msg['entities']['user_mentions']:
                for user in msg['entities']['user_mentions']:
                    usernames.append(user['screen_name'])

        return '<html><body>refresh to get new data<br/><br/>' + '<br/>'.join(usernames) + '</body></html>'

if __name__ == "__main__":
    app.run()
