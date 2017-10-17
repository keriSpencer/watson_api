class WatsonTweetsController < ApplicationController
  include HTTParty
  require 'open-uri'

  def index
    # 1. accept a twitter handle param
    username = params[:username]

    # 2. make a call to twitter to get all tweets for that user
    config = {
      consumer_key:    ENV['twitter_consumer_key'],
      consumer_secret: ENV['twitter_consumer_secret'],
    }

    client = Twitter::REST::Client.new(config)
    id = client.user(username).id
    timeline = client.user_timeline(id, {count: 200})

    # 3. flatten tweets to just their text
    tweets = timeline.map{ |tweet| tweet.text }

    # 4. feed that text into watson api
    options = { headers: { 'Access-Control-Allow-Origin' => '*',
                            'accept-language' => 'en', accept: 'application/json', 'content-type' => 'text/html'},
                body: { text: tweets.join('. ') }
              }

    personalities_auth = { basic_auth: { username: ENV['watson_username'], password: ENV['watson_password'] } }

    personalities_body = { body: { text: tweets.join('. ') } }

    personalities = HTTParty.post('https://gateway.watsonplatform.net/personality-insights/api/v3/profile?version=2017-10-13&consumption_preferences=true&raw_scores=true', options.merge!(personalities_auth).merge!(personalities_body))
    tones = HTTParty.get('https://watson-api-explorer.mybluemix.net/tone-analyzer/api/v3/tone?version=2017-10-13&text=' + URI::encode(tweets.take(50).join('. ')))

    results = { personalities: personalities, tweets: tweets, tones: tones["document_tone"] }

    # 5. return as json: the data and tweets
    render json: results
  end
end
