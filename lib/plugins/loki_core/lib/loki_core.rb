class LokiCore < LokiPluginBase
  
  def initialize_commands
    command /^what time.*/i, :what_time_is_it
    command /^what.+?(day|date).*/i, :what_day_is_it
    command /^how old are you.*/i, :how_old_are_you
    command /^clear/i, :clear
  end
  
  def clear(m)
    20.times do
      self.bot.say '.'
    end
  end
  
  def how_old_are_you(m)
    self.bot.say 'I don\'t know'
  end

  def what_day_is_it(m)
    self.bot.say(Date.today.to_s)
  end
  
  def what_time_is_it(m)
    self.bot.say(Time.now.strftime('%I:%M %p'))
  end
  
end