# encoding: UTF-8
require_relative 'picture_list'

EXTRA_TEXT = " #Letters"

# if you've been testing the bot's output, change the initial seed before
# release so that the bot can surprise you. Any integer should do.
INITIAL_SEED = 1777290

PICTURE_LINK_LENGTH = 23

# The bot is setup to have a chance to cc some bots that process images. You
# can tweak which accounts to send the images to (If you do this to humans that
# is likely going to classify your bot as spam. You don't want that).
#
# Put AT_PROB = 0.0  to disable this feature. 

AT_PROB = 1.0 / 10.0

# List of users it might send pictures to:
AT_USERS = [
    "Lowpolybot",
    "cgagraphics",
    "pixelsorter",
    "badpng",
    "a_quilt_bot",
    "JPGglitchbot",
]
# A small text to add before the @user:
AT_USER_ADD = ". cc "

# tweak the PICS constant, with initial seed: 
PICS.sort!
PICS.shuffle!( random: Random.new(INITIAL_SEED) )
class Content
    
    def get_next_index()
        ## Gets the next picture index to post.

        if @bot != nil
            image_index = @bot.twitter.user.statuses_count
        else
            image_index = @test_counter
            @test_counter = @test_counter + 1 
        end
        # The sequence is repeated each PICS.size, find the number of repetition 
        repetition_index = image_index / PICS.size
   
        # find if the index will belong to the first or second half of the sequence
        if image_index % PICS.size < PICS.size / 2
            # determine seed deterministically from repetition_index and the half
            seed = 2*repetition_index
            # we will pick an index from the first half 
            seq = ( 0.. (PICS.size/2-1) ).to_a
            x = image_index % PICS.size
        else
            # same but now the second half
            seed = 2*repetition_index + 1
            seq = ( PICS.size/2 .. PICS.size - 1 ).to_a
            x = image_index % PICS.size - PICS.size / 2
        end
        
        r = Random.new(seed)
        seq.shuffle!( random: r ) #shuffle the indexes using that seed 
        return seq[x] # pick the index
    end


    def initialize(bot = nil)
        ## For initialization we do need to keep track of the bot
        ## this way get_next_index can make use of the twitter client
        @bot = bot
        if @bot == nil
            # if @bot is nil this means we are testing the content in
            # testcontent.rb, with no access to twitter api to grab the tweet
            # count we better simulate one:
            @test_counter = 0
        end
    end
    
    def get_tokens()
        ## 'special' , 'interesting' and 'cool' keywords ##
        ## these are keywords that make tweets more likely to get faved, RTed
        ## or replied (some restrictions in botconfig.rb apply)

        ## We don't want the bot to do any interactions, so no tokens needed.
        return [],[],[]
    end
    
    def command(text)
        ## advanced , if bot owner sends the bot something starting with ! it is
        ## sent to this method. If nil is returned, the bot does nothing, else
        ## if a string is returned, the bot sends it back.
        return nil
    end
    
    def dm_response(user, text, lim)
        # This bot won't reply to DMs.
        return nil
    end
    
    def tweet_response(tweet, text, lim)
        # This bot won't reply to tweets.
        return nil
    end
    
    def hello_world(lim)
        # Return a string to send by DM to the bot owner when the bot starts
        # execution, useful for debug purposes. But very annoying if always on
        # Leave nil so that nothing happens.
        return nil
    end
    
    def make_tweets(lim, special)
        # Picks text and an image to tweet.
        # - first element of return value is the text.
        # - second element is the image.

        # Get the index of the picture to post
        i = get_next_index()

        # Should we at someone else in this?
        s = PICS[i][1] + EXTRA_TEXT
        if s.size > lim
            s = s[0..(lim-1)]
        else
            otherbot = ""
            if rand < AT_PROB
                otherbot = AT_USERS[ rand( 0..(AT_USERS.size - 1) ) ]
                otherbot = "#{AT_USER_ADD}@#{otherbot}"
            end
            if (s + otherbot).size <= lim
                s = s + otherbot
            end
        end

        # text, image:
        return s , File.new(PICS[i][0])
    end
    
    def special_reply(tweet, meta)
        # No special replies
        return nil
    end
    
end