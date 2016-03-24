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


require 'twitter_ebooks'
# Taken from twitter-ebooks : Temporary measure while migrating to twitter-ebooks 3.0
#require 'ostruct'
#require 'fileutils'


bots = Ebooks::Bot.all

threads = []
bots.each do |bot|
  threads << Thread.new { bot.prepare }
end
threads.each(&:join)

threads = []
bots.each do |bot|
  threads << Thread.new do
    loop do
      begin
        bot.start
      rescue Exception => e
        bot.log e.inspect
        puts e.backtrace.map { |s| "\t"+s }.join("\n")
      end
      bot.log "Sleeping before reconnect"
      sleep 60
    end
  end
end
threads.each(&:join)


