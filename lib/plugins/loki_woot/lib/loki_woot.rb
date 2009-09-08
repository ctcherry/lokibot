require 'thread'

class LokiWoot < LokiPluginBase

  attr_accessor :last_parsed_results, :sleep_interval, :thread, :tracking

	def initialize_commands
	  self.thread = nil
	  self.tracking = false
	  self.sleep_interval = 60

    command /^check woot*/i, :check_woot
		command /^track woot*/i, :track_woot
		command /^woot[-\s]?off.*/i, :track_woot
		command /^start tracking woot*/i, :track_woot
		command /^stop tracking woot*/i, :stop_tracking_woot
	end
	
	def check_woot(m)
	  paste_results parse_woot
  end
	
	def stop_tracking_woot(m)
	  if !self.tracking
	    self.bot.say 'I wasn\'t tracking woot!'
	  else
	    self.tracking = false
	    exit_tracking_thread
	    self.bot.say 'No longer tracking woot!'
	  end
  end
	
	def track_woot(m)
	  if self.tracking
	    self.bot.say 'I am already tracking woot!'
	  else
	    self.tracking = true
	    self.last_parsed_results = {}
	    self.bot.say 'Now tracking woot!'
	    create_tracking_thread
	  end
  end
  
protected

  def parse_woot
    str = get_url 'http://woot.com'
		match_names = [ :name, :price, :forum_link, :comment_count, :image ]
		matches = str.scan(/ContentPlaceHolder_TitleHeader\">(.+)<\/h3>.*?PriceSpan\">\$(.+?)<.+?ForumsLink.+?href=\"(.+?)\".+?\((\d+).+?SaleImage.+?src=\"(.+?)\"/imx)[0]
		Hash[*matches.collect{ |s| [match_names[matches.index(s)], s] }.flatten]
  end
  
  def paste_results(results)
    self.bot.paste "#{results[:name]} - #{results[:price]}\n#{results[:comment_count]} comments"
    self.bot.say 'http://woot.com'
    self.bot.say results[:image]
  end
  
  def create_tracking_thread
    if self.thread.nil?
      self.thread = Thread.new do
        while true do
          results = parse_woot
          if results[:name] != self.last_parsed_results[:name]
            paste_results(results)
            self.last_parsed_results = results
          end
          sleep self.sleep_interval
        end
      end
    end
  end
  
  def exit_tracking_thread
    self.thread.exit if self.thread.is_a? Thread
    self.thread = nil
  end

end
