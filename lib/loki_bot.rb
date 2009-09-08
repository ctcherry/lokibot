class LokiBot
  
  attr_accessor :active, :bot, :config, :debug, :dispatcher, :trigger
  
  def initialize(options = {})
    options = { :config => nil, :config_file => 'config/lokibot.yml' }.merge(options)
    
    full_config = YAML.load_file(options[:config_file])
    config = options[:config].nil? ? full_config[full_config.keys[0]] : full_config[options[:config]]
    
    self.debug = config['debug'] || DEBUG
    self.trigger = config['trigger'] || TRIGGER

    self.bot = Marshmallow.new(:domain => config['domain'])
    self.bot.login(:url => config['public_url'], :username => config['bot_name'])
    self.bot.say('== LokiBot Active ==') if self.debug
    
    self.config = config
    self.dispatcher = LokiDispatcher.new(:bot => self.bot)
  end
  
  def deactivate
    puts 'Deactivating...'
    self.active = false
    self.bot.leave
  end
  
  def start_listening
    self.active = true
    puts 'LokiBot Listening'
    message_loop
    puts 'LokiBot Done Listening'
  end
  
private

  def message_loop
    while(self.active)
      self.bot.watch do |m|
        process_message m if m[:message].match(/^#{trigger_pattern}/i)
      end
      sleep 2
    end
  end
  
  def process_message(m)
    m[:message].gsub!(trigger_pattern, '')
    self.bot.say "Command (#{m[:message]}) received from #{m[:person]}!" if self.debug
    self.dispatcher.process_message(m)
  end
  
  def trigger_pattern
    /#{@trigger}(?:\,\s*|\:\s*|\s)/i
  end
  
end