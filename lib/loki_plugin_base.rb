require 'open-uri'
require 'cgi'

class LokiPluginBase
  
  attr_accessor :bot, :commands
  
  def initialize(bot)
    self.bot = bot
    self.commands = []
    initialize_commands
  end
  
  def initalize_commands
  end
  
  def command(pattern, method)
    self.commands << { :pattern => pattern, :method => method }
  end
  
  def get_url(url)
    URI.parse(url).read
  end
  
  def post_url(url, vars)
  end
  
  def process_message(m)
    responded = false
    self.commands.each do |command|
      if m[:message] =~ command[:pattern]
        send command[:method], m
        responded = true
      end
    end
    responded
  end
  
end