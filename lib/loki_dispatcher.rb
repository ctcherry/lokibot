class LokiDispatcher
  
  attr_accessor :bot, :plugins, :unknown_command_responces
  
  def initialize(options = {})
    self.bot = options[:bot]
    self.plugins = []
    load_dependancies
  end
  
  def no_command_responded
    self.bot.say self.unknown_command_responces[rand(self.unknown_command_responces.length)]
  end
  
  def process_message(m)
    responded = false
    load_dependancies and responded = true if m[:message] == 'reload'
    self.plugins.each do |plugin|
      responded ||= plugin.process_message(m)
    end
    no_command_responded unless responded
  end
  
private

  def plugin_instance(path)
    class_name = Inflector.classify(path.scan(/loki\w+/))
    instance_eval("#{class_name}.new(self.bot)")
  end
  
  def load_plugins
    self.bot.say 'Loading plugins' if DEBUG
    
    reloading = true if self.plugins.length > 0
    self.plugins.clear
    
    plugin_files = Dir.glob(File.join('lib', 'plugins', 'loki_*'))
    
    plugin_files.each do |f|
      $:.push "#{f}/lib" unless $:.include? "#{f}/lib"
      load "#{f}/init.rb"
      self.plugins.push plugin_instance(f)
    end
    
    self.bot.say 'Reload complete.' if reloading
  end

  def load_dependancies
    load_plugins
    load_unknown_command_responces
  end
  
  def load_unknown_command_responces
    self.unknown_command_responces = IO.readlines(File.join('config', 'unknown_command_responces.txt')) || []
  end
  
end