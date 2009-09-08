class LokiGoogle < LokiPluginBase
  
  def initialize_commands()
    command /^(google image search|img).*/i, :image_search
    command /^google search.*/i, :search
  end
  
  def image_search(m)
    random = (m[:message] =~ /\-\-random/i)
    query = m[:message].gsub(/^google images? search/i, '')
    query.gsub!(/\-\-random/i, '') if random
    
    query = CGI.escape(query.chomp)
    str = get_url "http://images.google.com/images?q=#{query}"
    
    results = str.scan(/dyn\.Img\(\"http(?:.+?)(http\:\/\/.+?)\"/ixm)
    
    if random
      result = results[rand(results.length)][0]
    else
      result = results[0][0]
    end
    
    self.bot.say result
  end
  
  def search(m)
    m[:message]
  end
  
end