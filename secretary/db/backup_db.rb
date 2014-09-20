require 'rubygems'
require_relative '../configuration'


module Secretary

  class Backuper
    
    DUMP_PATH = 'db/dump.sql'
  
  
    # dump DB into the file
    def self.backup
      system "#{Configuration['mysql_dir']}mysqldump --user=#{Configuration['db_user']} --password=#{Configuration['db_password']} --host=#{Configuration['db_host']} #{Configuration['db_name']} > #{DUMP_PATH}"
    end


    # restore DB from the dump file
    def self.restore
      system "#{Configuration['mysql_dir']}mysql --user=#{Configuration['db_user']} --password=#{Configuration['db_password']} --host=#{Configuration['db_host']} #{Configuration['db_name']} < #{DUMP_PATH}"
    end

    
  end

end


Secretary::Backuper.backup