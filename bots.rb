require 'twitter_ebooks'
require 'thread'

require_relative 'content'
require_relative 'botconfig'

# a credentials.rb file is needed to declare 4 constants:
#CONSUMER_KEY       = app consumer key
#CONSUMER_SECRET    = app consumer secret
#OAUTH_TOKEN        = ebooks account's oauth token (make sure it has write and DM access)
#OAUTH_TOKEN_SECRET = ebooks account's oauth token secret
require_relative 'credentials'

# ------------------------------------------------------------------------------
MAX_TWEET_LENGTH    = 140

TWEET_ERROR_MAX_TRIES = 3
TWEET_ERROR_DELAY     = 60

include Ebooks

BLACKLIST = USER_BLACKLIST.map{ |s| s.downcase }
AT_BLACKLIST = BLACKLIST.map{ |s| "@" + s }

IN_NEVER_UNFOLLOW_BACK = NEVER_UNFOLLOW_BACK.map{ |s| s.downcase }.to_set

class GenBot < Ebooks::Bot
  # Configuration here applies to all GenBots
  def configure
    # Users to block instead of interacting with
    self.blacklist = ['tnietzschequote']

    # Range in seconds to randomize delay when bot.delay is called
    self.delay_range = DELAY
  end

  def on_startup
        @bot = self
        @content = nil
        @last_tweeted = 0
        @last_reset = 0
        @in_reply_queue = {}
        @follow_back_check = {}
        @unfollow_back_check = {}
        @have_talked = {}
        @tweet_mutex = Mutex.new
        @last_scheduled = :none
        @ignore_schedule = defined?IGNORE_SCHEDULE
      
        @content = Content.new(@bot)
        @special_tokens, @interesting_tokens, @cool_tokens = @content.get_tokens()
        hw = @content.hello_world(MAX_TWEET_LENGTH)
        if hw != nil
          begin      
              @bot.twitter.direct_message_create( BOT_OWNER, hw  )
          rescue
              @bot.log "Unable to send DM to bot owner: #{BOT_OWNER}.\n"
          end
        end
        @last_tweeted = minutes_since_last_tweet(@bot.twitter.user.id)
        @bot.log "#{@last_tweeted.to_s} minutes since latest tweet."
        
        
        scheduler.every '1m' do
            if !@ignore_schedule && !should_it_be_on()
                @bot.log "Bot process caught running off allowed time. Exit."
                @bot.log 'If you are just testing the bot use "ruby run.rb --ignore-schedule"'
                exit
            end
            gm = Time.new.gmtime 
            h = gm.hour  
            m = gm.min    
            special = :none
            SPECIAL_MESSAGES_SCHEDULE.each do |item|
                hc, mc, val = item
                if hc == h
                    if mc.is_a? Range
                        if mc.include? m
                            special = val
                        end
                    else
                        if mc == m
                            special = val
                        end
                    end
                end
            end
            disable_special = false
            if (@last_scheduled != :none) && (@last_scheduled == special)
                disable_special = true
            end
            @last_scheduled = special
            @tweet_mutex.synchronize do
                @last_tweeted = @last_tweeted + 1
                if ( (special != :none) && ! disable_special) || (@last_tweeted >= MAX_TWEET_PERIOD) || ( (@last_tweeted >= MIN_TWEET_PERIOD) && (rand < TWEET_RATE) )
                    if disable_special
                        do_tweet_chain(:none)
                    else
                        do_tweet_chain(special)
                    end
                end
            end
            @last_reset = @last_reset + 1
            if (@last_reset > MAX_RESET_PERIOD) && (rand < RESET_RATE)
                 @last_reset = 0
                 @have_talked = {}
                 @follow_back_check = {}
                 @unfollow_back_check = {}
            end
        end
  end

  def on_message(dm)
      if (dm.sender.screen_name == BOT_OWNER) && (dm.text.start_with?"!")
          if dm.text.start_with?"!tweet"
              @last_tweeted = MAX_TWEET_PERIOD + 1
          end
          s = dm.text.split(" ")
          if s.size > 1
              # These commands exist because there are legitimate use cases for
              # them. If you use these commands to break ToS, expect the app
              # to become read only or your bot's account or even your account
              # to be suspended.
              if s[0] == "!reply"
                  r = s[1].scan(/\d+/).first
                  reply_command(r)
              elsif s[0] == "!follow" || s[0] == "!unfollow" || s[0] == "!block" || s[0] == "!reportspam"
                  begin
                      if s[0] == "!follow"
                          @bot.follow s[1]
                          # we don't want the bot to unfollow them instantly...
                          @unfollow_back_check[s[1].downcase] = true
                      elsif s[0] == "!unfollow"
                          unfollow s[1]
                      elsif s[0] == "!block"
                          # Block command in case undesirable people follow your
                          # bot or attempt to exploit it.
                          block s[1]
                      elsif s[0] == "!reportspam"
                          # Once your bot becomes popular, specially if it 
                          # follows-back, it will start getting followed by 
                          # spammers, hence why a report spam function is useful
                          report_spam s[1]
                      end
                  rescue
                      @bot.log "Unable to #{s[0]}: #{s[1]}."
                  end
              end
          end
          # content class can have commands of its own too 
          s = @content.command(dm.text)
          if s != nil
              bot.reply dm, s
          end
      else
          @bot.delay DELAY do
              text = @content.dm_response(dm.sender, dm.text, MAX_TWEET_LENGTH)
              if text == nil
                  @bot.log "Content returned no response for DM."
              else
                  @bot.reply dm, text
              end
          end
      end

  end

  def on_follow(user)
    if AUTO_FOLLOW_BACK
       @bot.delay DELAY do
           @bot.follow user.screen_name
       end
    end
  end

  def on_mention(tweet)
    # Reply to a mention
    # reply(tweet, meta(tweet).reply_prefix + "oh hullo")
    if (REPLY_MODE == :disable_replies) && ! REPLY_FOLLOW_BACK
        return
    end
          uname = tweet.user.screen_name
          
          
          tokens = NLP.tokenize(tweet.text)
          return if tokens.find_all { |t| BLACKLIST.include?(t.downcase) || AT_BLACKLIST.include?(t.downcase)}.length > 0
          return if BLACKLIST.include?(uname.downcase)
          
          if REPLY_FOLLOW_BACK
              # follow-back maybe
              if ! @follow_back_check[uname] then
                  @follow_back_check[uname] = true
                  if @bot.twitter.friendship?(tweet.user, TWITTER_USERNAME) && ! @bot.twitter.friendship?(TWITTER_USERNAME, tweet.user)
                      @bot.delay DELAY do
                          @bot.log 'Follow-back: ' + uname + "\n"
                          @bot.twitter.follow tweet.user
                      end
                      # force a reply so that when somebody is followed-back this way
                      # it is easier for owner to notice
                      if REPLY_MODE != :disable_replies
                          reply_queue(tweet, meta(tweet))
                      end
                      return
                  end
              end
          end
          
          if REPLY_MODE == :disable_replies
              return
          end
    
          # Avoid infinite reply chains even with bots that cannot be 
          # identified as such
          if rand < CHANCE_TO_IGNORE_MENTION
              @bot.log 'Ignored mention'
              return
          end
    
          # Avoid infinite reply chains (30% chance not to reply other bots)
          if is_it_a_bot_name(uname) && (rand < CHANCE_TO_IGNORE_BOT_MENTION)
              @bot.log 'Ignored bot mention'
              return              
          end
    
          reply_queue(tweet, meta(tweet))
    
  end

  def on_timeline(tweet)
      return if tweet.retweeted_status || tweet.text.start_with?('RT')
      uname = tweet.user.screen_name
      return if BLACKLIST.include?(uname.downcase)
      
      if AUTO_UNFOLLOW_BACK
          if ! @unfollow_back_check[uname]
              @bot.log "Follow back check: @" + uname
              @unfollow_back_check[uname] = true
              if !@bot.twitter.friendship?(tweet.user, TWITTER_USERNAME)
                  # doesn't follow back, wtf is the user doing in this timeline?
                  if ! (IN_NEVER_UNFOLLOW_BACK.include?uname.downcase)
                      @bot.log "Unfollow"
                      unfollow uname
                      return # so the bot doesn't bother interacting
                  else
                      @bot.log "User is in NEVER_UNFOLLOW_BACK"
                  end
              else
                  @bot.log "User follows back."
              end
          end
      end
      
      s = @content.special_reply(tweet, meta)
      if s != nil
          bot.delay DELAY do
              bot.reply tweet, s
          end
          return
      end
      tokens = NLP.tokenize(tweet.text)
      # We calculate unprompted interaction probability by how well a
      # tweet matches our keywords
      interesting = tokens.find_all { |t| @interesting_tokens.include?(t.downcase) }.length >= INTERESTING_NEEDED
      cool = tokens.find_all { |t| @cool_tokens.include?(t.downcase) }.length > COOL_NEEDED
      special = tokens.find_all { |t| @special_tokens.include?(t.downcase) }.length >= SPECIAL_NEEDED

      do_reply = false
      do_fave  = false
      do_rt    = false

      if special
            do_fave = (rand < SPECIAL_FAVE_RATE )
      end
      
      if cool || special
          do_fave  = ( do_fave || (rand < COOL_FAVORITE_RATE) )
          do_rt    = (rand < COOL_RT_RATE)
          do_reply = (rand < COOL_REPLY_RATE )
      elsif interesting
          do_fave  = ( do_fave || (rand < INTERESTING_FAVORITE_RATE) )
          do_reply = (rand < INTERESTING_REPLY_RATE)
          do_rt    = (rand < INTERESTING_RT_RATE)
      end
      if (tweet.text.count "@") > 0
          do_reply = false
          do_rt = false
      end
      
      isBot = is_it_a_bot_name(tweet.user.screen_name)
      if ONLY_REPLY_RT_BOTS
          if (tweet.user.screen_name != BOT_OWNER) &&  ! isBot
              do_reply = false
              do_rt = false
          end
      end
      
      # Any given user will receive at most one random interaction per day
      # (barring special cases)
      if !@have_talked[tweet.user.screen_name]
          if do_fave
              favorite(tweet)
          end
          if do_rt
              retweet(tweet)
          end
          if do_reply
              reply_queue(tweet, meta)
          end
          if do_rt || do_reply
              @have_talked[tweet.user.screen_name] = true
          end
      end

  end

  def on_favorite(user, tweet)
    # Do nothing
  end

  def on_retweet(tweet)
    # Do nothing
  end
  
  # return 0 on failure
  def minutes_since_last_tweet(userid)
      x = 0
      begin
          t = @bot.twitter.user_timeline(count:1).first.created_at
          x = [ 1 , ((Time.now - t) / 60).ceil ].max
      rescue => e
          x = 0
          @bot.log "Error fetching latest tweet. Assuming 0 minutes since the latest tweet."
          @bot.log(e.message)
      end
      return x
  end
  
  def tweet_with_media(text, img, sensitive = nil, reply_to = 0)
      s1  = "Tweeting"
      if reply_to != 0
          s1 = "Adding"
      end
      s2 = ""
      if sensitive == :sensitive_media
          sensitive = true
          s2 = "sensitive "
      else
          sensitive = false
      end
      @bot.log "#{s1} [#{text}] with #{s2}image [#{img.path}]"
      begin
          return @bot.twitter.update_with_media(text, img, possibly_sensitive: sensitive, in_reply_to_status_id: reply_to )
      rescue => e
          @bot.log(e.message)
          @bot.log(e.backtrace.join("\n"))
          return nil
      end
  end
  
  def do_tweet_chain(special = :none)
      @last_tweeted = 0
      if @content.method(:make_tweets).arity == 2
          tw = @content.make_tweets( MAX_TWEET_LENGTH, special )
      else
          tw = @content.make_tweets(MAX_TWEET_LENGTH)
      end
      if tw == nil
          # if text is nil  then content is not ready , wait for another chance
          @last_tweeted = MAX_TWEET_PERIOD + 1
          @bot.log "tweet: Waiting for content."
      else
          if tw.is_a? String
              tw = [ [tw] ]
          end
          if tw[0].is_a? String
              tw = [tw]
          end

          last_tweet = nil
          last_tweet_id = 0
          for t in tw
              if last_tweet_id != 0
                  sleep rand TWEET_CHAIN_DELAY
              end
              text, img, sensitive = t
              tries = 0
              while (tries == 0 || (last_tweet == nil)) && (tries < TWEET_ERROR_MAX_TRIES)
                  if tries != 0
                      sleep TWEET_ERROR_DELAY
                  end
                  begin
                      if img != nil
                          last_tweet = tweet_with_media(text, img, sensitive, last_tweet_id)
                      elsif last_tweet_id == 0
                          last_tweet = @bot.tweet(text)
                      else
                          last_tweet = @bot.reply( last_tweet, text )
                      end
                  rescue => e
                      @bot.log(e.message)
                      @bot.log(e.backtrace.join("\n"))
                      last_tweet = nil
                  end
                  tries = tries + 1
                  if last_tweet == nil
                      @bot.log("Error detected")
                  end
              end
              if last_tweet != nil
                  last_tweet_id = last_tweet.id
              end
          end
          @last_tweeted = 0
      end
      
  end

  def reply_queue(tweet, meta)
    if @in_reply_queue[ tweet.user.screen_name.downcase ]
        @bot.log "@" + tweet.user.screen_name + " is already in reply queue, ignoring new mention."
        return
    end
    @in_reply_queue[ tweet.user.screen_name.downcase ] = true
    @bot.log "Add @" + tweet.user.screen_name + " to reply queue."
    if REPLY_MODE == :reply_to_single
        # always @ only the person who @-ed the bot:
        if tweet.user.screen_name == TWITTER_USERNAME
            rp = ''
        else
            rp = '@' + tweet.user.screen_name + ' '
        end
    else
        rp = ''
        for s in meta.reply_prefix.split(" ")
            if rp == ''
                rp = s + " "
            elsif ! is_it_a_bot_name(s)
                rp = rp + s + " "
            end
        end
        if (tweet.text.count "@") > 4
            # too many @-s probably a user trying to exploit bots
            rp = '@' + tweet.user.screen_name + ' '
        end
    end
    Thread.new do
      @tweet_mutex.synchronize do
        sleep rand DELAY
        begin
            response = @content.tweet_response(tweet, meta.mentionless, MAX_TWEET_LENGTH - rp.size)
            if response.is_a?String
                response = [response]
            end
        rescue Exception => e
            @bot.log(e.message)
            @bot.log(e.backtrace.join("\n"))
            response = nil
        end
        if response == nil
            @in_reply_queue[ tweet.user.screen_name.downcase ] = false
            @bot.log "Content returned no response."
            @bot.log "Remove @" + tweet.user.screen_name + " from reply queue."
            return
        end
        sensitive = response.delete(:sensitive_media)
        dotreply = response.delete(:dot_reply)
        single = response.delete(:reply_to_single)
        if single == :reply_to_single
            # again :(
            if tweet.user.screen_name == TWITTER_USERNAME
                rp = ''
            else
                rp = '@' + tweet.user.screen_name + ' '
            end        
        end
        text, img = response
        text = rp + text
        if dotreply == :dot_reply
            text = "." + text
        end
        error_happened = false
        tries = 0
        while (tries == 0 || error_happened) && (tries < TWEET_ERROR_MAX_TRIES)
            if tries != 0
                sleep TWEET_ERROR_DELAY
            end
            error_happened = false
            begin
                if img != nil
                    made_tweet = tweet_with_media(text, img, sensitive, tweet.id )
                else
                    #made_tweet = @bot.reply tweet, text
                    made_tweet = twitter.update(text, {in_reply_to_status_id: tweet.id})
                end
                if made_tweet == nil
                    error_happened = true
                end
            rescue => e
                  @bot.log(e.message)
                  @bot.log(e.backtrace.join("\n"))
                  error_happened = true
            end
            tries = tries + 1
        end
        
        @bot.log "Remove @" + tweet.user.screen_name + " from reply queue."
        @in_reply_queue[ tweet.user.screen_name.downcase ] = false
        # one last sleep during the mutex to guarantee the next non-reply tweet
        # won't be immediate
        sleep rand DELAY
      end
    end
  end

  def favorite(tweet)
    @bot.log "Favoriting @#{tweet.user.screen_name}: #{tweet.text}"
    @bot.delay FAV_DELAY do
      @bot.twitter.favorite(tweet[:id])
    end
  end

  def retweet(tweet)
    @bot.log "Retweeting @#{tweet.user.screen_name}: #{tweet.text}"
    @bot.delay FAV_DELAY do
      @bot.twitter.retweet(tweet[:id])
    end
  end
  
  def unfollow(user)
      @bot.log "Unfollowing #{user}"
      @bot.twitter.unfollow user
  end
  
  def block(user)
      @bot.log "Blocking @#{user}"
      @bot.twitter.block(user)
  end

  def report_spam(user)
      @bot.log "Reporting @#{user}"
      @bot.twitter.report_spam(user)
  end

  def reply_command(tweetId)
      begin
          ev = @bot.twitter.status(tweetId)
      rescue
          @bot.log "Could not retrieve tweet: " + tweetId.to_s
          return
      end
      # now send to the queue.
      reply_queue(ev, meta(ev) ) 
  end
  
end

# Make a MyBot and attach it to an account
GenBot.new(TWITTER_USERNAME) do |bot|
  bot.access_token        = OAUTH_TOKEN        # Token connecting the app to this account
  bot.access_token_secret = OAUTH_TOKEN_SECRET # Secret connecting the app to this account
  bot.consumer_key        = CONSUMER_KEY
  bot.consumer_secret     = CONSUMER_SECRET 
end
