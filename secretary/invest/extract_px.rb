require 'rubygems'
require 'mysql'
require 'csv'
require 'open-uri'
require 'parseconfig'


# load configuration
config = ParseConfig.new('extractor.cfg')
db_host = config['db_host']
db_user = config['db_user']
db_password = config['db_password']
db_name = config['db_name']
min_date = config['min_date']


# connect to db
begin
  db = Mysql.new(db_host, db_user, db_password, db_name)
rescue
  puts "ERROR - Unable to connect to the data base"
  exit 1;
end


# find last record
query = "select max(day) from px" 
result = db.query(query)
row = result.fetch_row()
last_date = row[0].nil? ? Date.parse(min_date) : Date.parse(row[0])


# download px price list
File.open('data/px.csv', "wb") do |file|
  file.write open('http://ftp.pse.cz/Info.bas/Cz/PX.csv').read
end


# find new records
records = CSV.read("data/px.csv")
new_records = records.select { |row| Date.parse(row[0], "%d.%m.%Y") > last_date }
puts "New records found: #{new_records.length}"


# load new records
if (new_records.length > 0)
  values = new_records.map { |r| "(str_to_date('#{r[0]}', '%d.%m.%Y'),#{r[1]})" }.join(",")
  query = "insert into px (day, value) values #{values};"
  result = db.query(query)
  puts result
end
