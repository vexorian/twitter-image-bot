BOT_OWNER = 'your-twitter-user-name'
TWITTER_USERNAME = "test245632" # Ebooks account username

AUTO_FOLLOW_BACK = false

# if true, when there is a tweet in the timeline, the bot will check if the user
# follows the bot. If not, the bot will unfollow the account, unless account is
# listed in NEVER_UNFOLLOW_BACK
AUTO_UNFOLLOW_BACK = true 

#list of handles that the bot won't unfollow back:
NEVER_UNFOLLOW_BACK = [ 'twitter' , 'support', 'safety' ] 

# If true then the bot will be able to follow-back accounts that follow the 
# bot AND interact with the bot. 
REPLY_FOLLOW_BACK = true

# If true the bot will only reply or RT accounts that are identified as bots. 
ONLY_REPLY_RT_BOTS = true

DELAY             = 2..70   # Delay between seeing a tweet and interacting (RT / reply)
FAV_DELAY         = 30..100 # Same but for favoriting the tweet
TWEET_CHAIN_DELAY = 10..40  # Delay for tweets in a single chain (if content provides)

# probability to make a random tweet at a given minute:
TWEET_RATE       = 1 / 60.0
# maximum number of minutes between tweets
MAX_TWEET_PERIOD = 60
# minimum number of minutes between tweets (ignoring scheduled and manual ones)
MIN_TWEET_PERIOD = 15

# Schedule some special messages, to be used by content at given times.
SPECIAL_MESSAGES_SCHEDULE = [
    [5, 58..59, :good_night],    #Post a good night message sometime between 5:58 and 5:59 GMT
    [12, 0.. 3, :good_morning],  #Good morning between 12:00 or 12:03 GMT
    # [H, m, :some_name_to_be_sent_to_content ],
    # Times are in GMT, 24 horus format    
]

# A function to decide when to go to sleep (only used 
# if the bot is in heroku and the scheduler is setup)
def should_it_be_on()
    h = Time.new.gmtime.hour  # normally we base it upon the UTC hour value
    
    if 6 <= h && h < 12      #from 6 UTC to 12 UTC
        return false
    else
        return true
    end
end

# probability to reset the bot at a given minute.
# (resets the people bot has interacted with so they can interact again)
RESET_RATE       = 1 / 1000000.0 #rarely it may reset before the day ends
# you can just use 0.0 chance, I am not sure why I made this random vOv
# maximum number of minutes between resets
MAX_RESET_PERIOD = 24 * 60

# REPLY_MODE can be
#:reply_to_all    : All the people (except bots) @-ed in tweet are @-ed in reply
#:reply_to_single : Only @ the author of the tweet.
#:disable_replies : Disable replies altogether.
REPLY_MODE = :reply_to_all

# these probabilities are ignored (1.0) if :disable_replies
CHANCE_TO_IGNORE_MENTION = 0.05
CHANCE_TO_IGNORE_BOT_MENTION = 0.4

# Special, Interesting and Cool words are provided by the content class

# Number of special words needed in tweet to consider it "Special"
SPECIAL_NEEDED = 2
# Chance to favorite a special tweet.
SPECIAL_FAVE_RATE = 0.25

# Same for all of this:
INTERESTING_NEEDED = 1
INTERESTING_FAVORITE_RATE = 0.1
INTERESTING_RT_RATE = 0
INTERESTING_REPLY_RATE = 1.0 / 60.0

COOL_NEEDED = 3
COOL_FAVORITE_RATE = 0.5
COOL_RT_RATE = 0.1
COOL_REPLY_RATE = 1.0 / 30.0

# Twitter's api doesn't consider blocks, so if an annoying person or stalker
# is playing with your bot you need a way to make the bot ignore them completely
# Users in blacklist are ignored by the bot altogether, and also tweets that
# include the user @-ed will be ignored.

USER_BLACKLIST = [
   'twitterbothater1',
   'twitterbothater2',
   'twitterbothater3',
] 

# Bot interacts differently with other bots, but we need to identify them 
# somehow. This function determines if twitter handle belongs to a bot.
BOT_LIST = [
    "realgamer9001",
    "badideabot",
    "gamergatefacts",
    "wikisext",
    "lexicalorderbot",
    "but_if_you_can",
]
require "set"
BOT_SET = BOT_LIST.map{ |s| s.downcase }.to_set
def is_it_a_bot_name(username)
    u = username.downcase
    if u.start_with?"@"
        u = u[1..u.size]
    end
    if BOT_SET.include? u
        return true
    end
    return (u.include? "groot") || (u.end_with? "ebooks")    
end