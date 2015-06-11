# a credentials.rb file is needed to declare 4 constants:
#CONSUMER_KEY       = app consumer key
#CONSUMER_SECRET    = app consumer secret
#OAUTH_TOKEN        = ebooks account's oauth token (make sure it has write and DM access)
#OAUTH_TOKEN_SECRET = ebooks account's oauth token secret

#HEROKY_API_TOKEN   = (only needed if you are using the scheduler) Heroku API key.

#None of the following is considered a secure way to do this. Usually if you
# care about security you'd replace the string literals below with reading
# environment variables.
# (The security risk is that if anyone finds this file they'll gain total access to
#   your bot and even your heroku, you don't want that)

CONSUMER_KEY       = "xxxxxxxxxxxxxxxxxxxxxxxxx"
CONSUMER_SECRET    = "yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"
OAUTH_TOKEN        = "0000000000-zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
OAUTH_TOKEN_SECRET = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

HEROKU_APP_NAME    = "my-bot-test"
HEROKU_API_TOKEN   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
HEROKU_PROCESS_TYPE= "worker" # (You'd need to change ProcFile too)
