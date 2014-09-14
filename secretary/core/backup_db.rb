require 'rubygems'
require 'parseconfig'


# load configuration
config = ParseConfig.new('secretary.cfg')
db_host = config['db_host']
db_user = config['db_user']
db_password = config['db_password']
db_name = config['db_name']
mysql_dir = config['mysql_dir']


# dump into the file
system "#{mysql_dir}mysqldump --user=#{db_user} --password=#{db_password} --host=#{db_host} #{db_name} > dump.sql"

# restore from the dump file
###system "#{mysql_dir}mysql --user=#{db_user} --password=#{db_password} --host=#{db_host} #{db_name} < dump.sql"
