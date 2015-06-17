require 'platform-api'
require_relative 'botconfig'
require_relative 'credentials'

heroku = PlatformAPI.connect_oauth(HEROKU_API_TOKEN)

current = heroku.formation.info(HEROKU_APP_NAME, HEROKU_PROCESS_TYPE)['quantity']
should  = should_it_be_on()

mainten = heroku.app.info(HEROKU_APP_NAME)['maintenance']
if mainten
    should = false
end

wanted = 0
if should
    wanted = 1
end

if current != wanted
    puts "Changing scale from " + current.to_s + " to " + wanted.to_s + "."
    heroku.formation.update(HEROKU_APP_NAME, HEROKU_PROCESS_TYPE, {'quantity' => wanted} )
else
    puts "Current scale is already " + current.to_s + ", nothing to change."
end

if (wanted == 1) && (current == 1)
    # Make sure the process is up. It's possible it crashed and Heroku made it
    # go to sleep.
    bad = true
    begin
        heroku.dyno.list(HEROKU_APP_NAME).each do |x|
            if x["type"] == HEROKU_PROCESS_TYPE
               puts "#{x["name"]} is #{x["state"]}."
               if (x["state"] == "up") || (x["state"] == "starting")
                   bad = false
               end
            end
        end
    rescue => e
        bad = true
        puts "Error checking #{HEROKU_PROCESS_TYPE} process, restart"
    end
    if bad
        puts "Restarting dyno."
        heroku.dyno.restart(HEROKU_APP_NAME, HEROKU_PROCESS_TYPE)
    end
end

