class LokiDecider < LokiPluginBase
  
  def initialize_commands
    command /roll(.+?)dice/i, :roll_dice
    command /yes or no/i, :yes_or_no
    command /flip(.+)coin/i, :flip_coin
  end
  
  def flip_coin(m)
    side = (prob50) ? "Heads" : "Tails"
    self.bot.say side
  end
  
  def roll_dice(m)
    self.bot.say rand(6)+1
  end
  
  def yes_or_no(m)
    answer = (prob50) ? "Yes" : "No"
    self.bot.say answer
  end
  
private

  def prob50
    (rand(11) > 5)
  end
  
end