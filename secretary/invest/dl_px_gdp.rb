require 'rubygems'
require 'parseconfig'
require 'mysql'


# load configuration
config = ParseConfig.new('extractor.cfg')
db_host = config['db_host']
db_user = config['db_user']
db_password = config['db_password']
db_name = config['db_name']
mysql_dir = config['mysql_dir']


# fill temp table
system "#{mysql_dir}mysql --user=#{db_user} --password=#{db_password} --host=#{db_host} #{db_name} < sql/fill_px_gdp.sql"


# connect to db
begin
  db = Mysql.new(db_host, db_user, db_password, db_name)
rescue
  puts "ERROR - Unable to connect to the data base"
  exit 1;
end


# download data
data = String.new
#query = "select gdp.day, gdp.value gdp_value, px.value px_value from gdp, px where px.day = (select px.day from px where px.day <= gdp.day and px.value is not null order by px.day desc limit 1)"  # selects just days with gdp filled
query = "select day, px_value, gdp_value from ( select px.day, px.value px_value, gdp.value / 1000 gdp_value from px left outer join gdp on gdp.day = px.day union select gdp.day, px.value px_value, gdp.value / 1000 gdp_value from gdp left outer join px on gdp.day = px.day where px.value is null) temp order by day"  # full outer join of px and gdp
result = db.query(query)
result.each { |x| data += x.join(',') + "\n" }


# save to csv
File.open('data/px_gdp.csv', 'w') {|f| f.write(data) }