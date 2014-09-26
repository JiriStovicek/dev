require 'rubygems'
require 'parseconfig'
require 'date'
require 'logger'


class Configuration
    
  CONFIG_PATH = './secretary.cfg'
      

  def self.[](key)
    ParseConfig.new(CONFIG_PATH)[key]
  end
  
  
  def self.get_array(key)
    line = ParseConfig.new(CONFIG_PATH)[key]
    line.split(',').map { |x| x.strip() }
  end
    
end
