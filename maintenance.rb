require_relative 'credentials'
require 'platform-api'


if (ARGV.size != 1) || ( (ARGV[0] != 'on') && (ARGV[0] != 'off') )
    puts "     ruby maintenance.rb on"
    puts "- or -"
    puts "     ruby maintenance.rb off"
else
    heroku = PlatformAPI.connect_oauth(HEROKU_API_TOKEN)
    mainten = heroku.app.info(HEROKU_APP_NAME)['maintenance']
    val = (ARGV[0] == 'on')
    if (mainten == val)
        puts "Maintenance mode is already [#{ARGV[0]}]."
    else
        puts "Changing maintenance mode to [#{ARGV[0]}]."
    end
    heroku.app.update(HEROKU_APP_NAME, {'maintenance' => val} )
    load './scheduler.rb'
end

