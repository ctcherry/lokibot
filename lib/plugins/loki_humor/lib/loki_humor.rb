class LokiHumor < LokiPluginBase
  
  def initialize_commands
    command /^lol/i, :lol
  end
  
  def lol(m)
    self.bot.say 'What\'s so funny?'
  end
  
end