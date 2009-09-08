#!/usr/local/bin/ruby
#
# Marshmallow, the campfire chatbot
#
# You need to know one the following:
#  (a) the secret public URL, or
#  (b) an account/password for your room and the room number.
#
# Usage:
#   to login with a password:
#
#   bot = Marshmallow.new( :domain => 'mydomain', :ssl => true )
#   bot.login :method => :login,
#     :username  => "yourbot@email.com",
#     :password => "passw0rd",
#     :room     => "11234"
#   bot.say("So many ponies in here! I want one!")
#
#  to use the public url:
#
#    Marshmallow.domain = 'mydomain' 
#    bot = Marshmallow.new
#    bot.login( :url => 'aDxf3' )
#    bot.say "Ponies!!"
#    bot.paste "<script type='text/javascript'>\nalert('Ponies!')\n</script>"
#    bot.topic("We like ponies!")
#
#  to interact with others' messages:
#
#    while(true)
#    	bot.watch do |m|
#    	  bot.say("Hello, #{m[:person]}") if m[:message].match(/hello/i)
#    	end
#    	sleep 3
#    end
#

class Marshmallow
  require 'net/https'
  require 'open-uri'
  require 'cgi'
  require 'yaml'
  
  def self.version
    "0.3"
  end

  attr_accessor :domain

  def self.say(to, what)
    connect(to) { |bot| bot.say(what) }
  end
  
  def self.paste(to, what)
    connect(to) { |bot| bot.paste(what) }
  end
  
  # https://david:stuff@37s.campfirenow.com/rooms/11234
  def self.connect(to)
    if to =~ %r{(http|https)://([^:]+):(.+)@([^.]+).campfirenow.com/rooms/(\d+)}
      protocol, username, password, domain, room = $1, $2, $3, $4, $5
    else
      raise "#{to} didn't match format, try something like https://david:stuff@37s.campfirenow.com/rooms/11234"
    end

    bot = new(:domain => domain, :ssl => (protocol == "https"))
    bot.login(:username => username, :password => password, :method => :login, :room => room)

    yield bot
  end

  def initialize(options={})
    @debug  = options[:debug]
    @domain = options[:domain] || @@domain
    @ssl    = options[:ssl]
  end
  
  def login(options)
    options = { :method => :url, :username => 'Marshmallow' }.merge(options)
    
    @req = Net::HTTP::new("#{@domain}.campfirenow.com", @ssl ? 443 : 80)  
    @req.use_ssl = @ssl
    @req.verify_mode = OpenSSL::SSL::VERIFY_NONE if @ssl
    headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
    
    case options[:method]
    when :url
      res = @req.post("/#{options[:url]}", "name=#{options[:username]}", headers)
      # parse our response headers for the room number.. magic!
      @room_id = res['location'].scan(/room\/(\d+)/).to_s
      puts res.body if @debug
        
    when :login        
      params = "email_address=#{CGI.escape(options[:username])}&password=#{CGI.escape(options[:password])}"
      puts params if @debug
      res = @req.post("/login/", params, headers)
      @room_id = options[:room]
      puts "Logging into room #{@room_id}" if @debug
      puts res.body if @debug
    end
        
    @headers = { 'Cookie' => res.response['set-cookie'] }
    res2 = @req.get(res['location'], @headers)
    puts res2.body if @debug

    # refresh our headers
    @headers = { 'Cookie' => res.response['set-cookie'] }
    res3 = @req.get("/room/#{@room_id}/", @headers) # join the room if necessary
    @membershipKey = res3.body.scan(/\"membershipKey\": \"([a-z0-9]+)\"/).to_s
    @userID = res3.body.scan(/\"userID\": (\d+)/).to_s
    @lastCacheID = res3.body.scan(/\"lastCacheID\": (\d+)/).to_s
    @timestamp = res3.body.scan(/\"timestamp\": (\d+)/).to_s
    return @headers
  end
  
  def leave
    puts "logging out of #{@room_id}" if @debug
    res = @req.get("/#{@room_id}.leave", @headers)
  end
  
  def paste(message)
    say(message, true)
  end
  
  def watch
    puts "checking for new messages" if @debug
    messages = []
    res = @req.post("/poll.fcgi","l=#{@lastCacheID}&m=#{@membershipKey}&s=#{@timestamp}&t=#{Time.now.to_i.to_s + "000"}", @headers)
    if res.body.length > 1
      puts res.body if @debug
      chunks = res.body.split("\r\n")
      if chunks.length > 0
        @lastCacheID = chunks[-1].scan(/chat.poller.lastCacheID = (\d+)/).to_s
        chunks[0..-2].each do |msg|
        unless msg.match(/timestamp_message/)
          message = {}
          message[:id] = msg.scan(/message_(\d+)/).to_s
          message[:userID] = msg.scan(/user_(\d+)/).to_s
          message[:person] = msg.scan(/<span>(.+)<\/span>/).to_s
          message[:message] = msg.scan(/<div>(.+)<\/div>/).to_s
          messages << message
        end
        end
      end
    end
    if block_given?
      messages.each do |msg|
        yield msg
      end
    end
    messages
  end
  
  def topic(message)
    puts "Changing topic to #{message}" if @debug
    res = @req.post("/room/#{@room_id}/change_topic", "commit=Save&room[topic]=#{CGI.escape(message.to_s)}", @headers)
    puts res.body if @debug
  end
  
  def say(message, paste=false)
    puts "Posting #{message}" if @debug
    res = @req.post("/room/#{@room_id}/speak", "#{'paste=true&' if paste}message=#{CGI.escape(message.to_s)}", @headers)
    puts res.body if @debug
  end
end

if $0 == __FILE__
  if ARGV.size != 3
    puts "Usage: marshmallow https://username:password@domain.campfirenow.com/rooms/1234 [say|paste] 'Hello world!'"
  else
    print "Sending... "
    $stdout.flush

    to, how, what = *ARGV
    Marshmallow.send(how, to, what)

    puts "DONE!"
  end
end