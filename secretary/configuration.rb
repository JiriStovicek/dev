require 'rubygems'
require 'parseconfig'
require 'date'
require 'logger'


class Configuration
    
  CONFIG_PATH = './secretary.cfg'
      

  def self.[](key)
    ParseConfig.new(CONFIG_PATH)[key]
  end
    
end
