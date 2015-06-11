# twitter-bot-template
A ruby twitter bot template.

# Basic instructions
Actual documentation in the form of a tutorial coming soon, I hope.  In the meantime this repository should be of interest
to people already knowledgeable about twitter bots.

Required twitter_ebooks version is locked at 2.3.2, 3.0+ support will come soon (tm).

# Heroku scheduling
Soon apps hosted for free in Heroku will be limited to run 18 hours a day. If a bot
hosted in heroku has no awareness of this, Heroku will put it to sleep at unpredictable 
times of the day. This bot template offers a workaround to this issue. You know
have the freedom to schedule at which hours the bot should go to sleep.

Assuming you know how to setup a bot to run in Heroku, go to the dashboard, find the
bot's app and in the addons section add "Heroku Scheduler" , press save.

Then click on Heroku Scheduler, a new page will open. Click "Add Job" to add a
schedulable job. Type "ruby scheduler.rb" in the command. Select hourly at 00 minutes. You
may also try with every 10 minutes, but it might be overkill.

Control of the app's Heroku processes requires a Heroku api token (similar to twitter API tokens).

# credentials.rb
This file declares the twitter and heroku tokens. See the included example.credentials.rb file for more information.

# botconfig.rb
This sets a lot of variables, some are important (like who is the owner, what is the bot's name). How often to tweet. Etc.

# content.rb
The source of behavior for the bot. What tweets to make, how to reply. Support for custom commands...

# bots.rb
The core. All my twitter bots use the same bots.rb , config and content are the ones that make the difference. Note that this is really my first Ruby project so it could be bette.


# maintenance.rb
Because there's a scheduler process constantly turning the bot on and off, we need something to completely disable
execution of a bot in case we need to update it / do tests / no longer want heroku running it / etc.

A script you can run to enable or disable heroku's execution of your bot.
ruby maintenance.rb off , makes it run (unless the bot is scheduled not to run at the time)
ruby maintenance.rb on  , disables execution until we call it with 'off'.

# scheduler.rb
This is the part that might interest bot makers. Using the heroku API to send a bot to sleep or wake it up. The sleep times are
configured in botconfig.rb

# Other interesting features
* Tweet throtling , by default the minimum DELAY  is 30 seconds, meaning that the bot will make at most 2 tweets per minute regardless of circumstances.
* Depending of how you set up content, the bot can post images and tweet chains with/without images.
* Autofollow back : Instead of automatically following back anyone who follows, it follows back anyone who follows AND seems to interact with the bot.
* Auto unfollow back : If someone unfollows the bot, the bot will eventually find out and unfollow (you can setup exceptions)
* Commands : BOT_OWNER can send commands through DM and make the bot do things, see bots.rb for more info. Specially useful so you don't have to login as the bot to do simple things like following friends or blocking spamming.
* Schedulable tweets: Hard to explain but there's a way to setup schedulable tweets in botconfig.rb and then maybe make content.rb say special things in that case. 
This is how [@bmpbug's #on/#off messages](https://twitter.com/search?q=from%3Abmpbug%20%23on%20OR%20%23off&src=typd) work.
