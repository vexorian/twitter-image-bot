require 'twitter_ebooks'
require_relative 'content'

content = Content.new()

special, inter, cool = content.get_tokens()


print inter
print "\n"
print "\n"
print cool
print "\n"
print "\n"


for x in 0..200
    print "\n"
    did = false
    tx = content.make_tweets(140, :none)
    while tx == nil
        print "[not ready]"
        sleep(5)
        tx = content.make_tweets(140, :none)
    end
    print "[["+ tx.to_s + "]]"
    
    print "\n"
    print "\n"
end
