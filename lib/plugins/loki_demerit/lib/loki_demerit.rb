class LokiDemerit < LokiPluginBase

  attr_accessor :board

	def initialize_commands
    self.board = {}
    command /add (.+?) to (the )?board/i, :add_name
    command /show (the )?board/i, :status
  end
  
  def add_name(m)
    matches = m[:message].scan(/add (.+?) to (?:the )?board/i)
    name = (matches[0][0].match(/me/i)) ? m[:person] : matches[0][0]
    
    if name =~ /loki/i
      say "Loki does no wrong!"
      return true
    end
    
    key = name.downcase.gsub(/[^a-z]/, '_')
    if self.board.has_key?(key)
      self.board[key][:marks] += 1
      say "#{@board[key][:name]} has #{@board[key][:marks]} marks!"
    else
      self.board[key] = {:marks => 0, :name => name}
      say "Adding #{name} to the board"
    end

  end
  
  def status(m)
    self.board.each_pair do |key, person|
      message = (person[:marks] > 0) ? "#{person[:name]}#{ "  x" * person[:marks]}" : "#{person[:name]}"
      say message
    end
  end

end
