# encoding: UTF-8

def random_number
    # twitter gets angry at you if you post the exact same tweet multiple times
    # so we cannot just make a bot that says the same thing every time.
    # the second-simplest bot example is one that says a random number ...
    return rand(10000).to_s
end

class Content
    
    def initialize(bot = nil)
        ## any initializing code goes here, you might need access to the bot
        ## object, fear not, that's what the 'bot' argument is for. Usually
        ## content should aim to be independent. Specially so you can use
        ## testcontent.rb. Normally.
    end
    
    def get_tokens()
        ## 'special' , 'interesting' and 'cool' keywords ##
        ## these are keywords that make tweets more likely to get faved, RTed
        ## or replied (some restrictions in botconfig.rb apply)
        special     = ['bot', 'twitter']
        interesting = ['demo', 'magic']
        cool        = ['awesome', 'hello', 'world']
        return special, interesting, cool
        
        ## you can do:
        # return [],[],[]
        # if you want none of this
    end
    
    def command(text)
        ## advanced , if bot owner sends the bot something starting with ! it is
        ## sent to this method. If nil is returned, the bot does nothing, else
        ## if a string is returned, the bot sends it back.
        
        # Example: a !test command makes the bot say reply the DM with 
        # "test complete":
        if text.include?"!test"
            return "test complete. Have a random number: #{random_number}"
        end
    end
    
    def dm_response(user, text, lim)
        # How to reply to DMs with a text from user. lim is the limit (usually 140)
        # If return is nil , the bot won't reply.
        return "Nice DM message. Have a random number: #{random_number}"
    end
    
    def tweet_response(tweet, text, lim)
        # How to reply to @-mentions.
        # text : Contains the contents of the tweet minus the @-mentions
        # lim  : Is the character limit for the reply. Don't exceed it.
        #        Because the bot needs to include other @-mentions in the reply
        #        this limit is not always 140.
        # tweet: Is an object from the sferik twitter library has 
        #
        s = "Nice reply. Have a random number: #{random_number}"
        if s.size > lim
            # don't exceed lim (it is possible many users are in the chat and 
            # thus the lim is smaller, don't reply in that case.
            return nil
        else
            return s
        end
    end
    
    def hello_world(lim)
        # Return a string to send by DM to the bot owner when the bot starts
        # execution, useful for debug purposes. But very annoying if always on
        # Leave nil so that nothing happens.
        return nil
    end
    
    def make_tweets(lim, special)
        # This just returns a tweet for the bot to make.
        return "This is a tweet. Random number: #{random_number}"
        
        
        # In reality there are many additional things to know:
        #
        # return some_string,  some_file_object 
        #
        #  will return a tweet AND attach the file object as media. Typically
        #   use this for posting images in twitter.
        #
        # return [
        #    [ "hi" ],
        #    [ "you"],
        # ]
        #
        # This makes a tweet chain, first posts "Hi" then adds a "you" tweet to
        # the chain.
        #
        # There are far more things you should know, like what 'special' is 
        # about. Hope to have better examples / documentation later.
        # 
        # Return nil if the content is not ready yet, the code will call 
        # make_tweets at another time.
        #
    end
    
    def special_reply(tweet, meta)
        # This allows you to react to tweets in the time line. If the return
        # is a string, it will reply with that tweet (you need to include the
        # necessary @-s). If the return is nil, do nothing:
        
        
        # in this example whenever someone the bot follows types a tweet 
        # containing "iddqd", the bot will reply saying "invincible"
        if tweet[:text].include? "iddqd"
            return meta[:reply_prefix] + ' degreelessness mode on.'
        end
        # you should really remove this example after testing it.
        return nil
    end
    
    
end

