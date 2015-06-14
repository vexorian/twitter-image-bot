#!/usr/bin/env ruby


require_relative 'botconfig'

ignore_schedule = ARGV.include?"--ignore-schedule"
if ignore_schedule
    IGNORE_SCHEDULE = true
    puts "Will ignore schedule."
elsif !should_it_be_on()
    puts 'Bot process started outside schedule. Halting'
    puts 'If you are just testing the bot use "ruby run.rb --ignore-schedule"'
    exit
end


require_relative 'bots'

EM.run do
 Ebooks::Bot.all.each do |bot|
    bot.start
  end
end
