require 'rubygems'
require 'mysql'
require 'csv'
require 'open-uri'
require 'logger'
require_relative 'configuration'


# start logging
log = Logger.new(Configuration['log_file'])
log.debug("PX extract started")


# connect to db
begin
  db = Mysql.new(Configuration['db_host'], Configuration['db_user'], Configuration['db_password'], Configuration['db_name'])
rescue
  log.error("Unable to connect to the database")
  exit 1;
end


# find last record
query = "select max(day) from px" 
result = db.query(query)
row = result.fetch_row()
last_date = row[0].nil? ? Date.parse(min_date) : Date.parse(row[0])
log.debug("Last PX record found: #{last_date}")


# download px price list
fname = 'data/px.csv'
File.open(fname, "wb") do |file|
  file.write open('http://ftp.pse.cz/Info.bas/Cz/PX.csv').read
end
log.debug("PX source downloaded to #{fname}")


# find new records
records = CSV.read("data/px.csv")
new_records = records.select { |row| Date.parse(row[0], "%d.%m.%Y") > last_date }
log.debug("New PX records found: #{new_records.length}")


# load new records
if (new_records.length > 0)
  values = new_records.map { |r| "(str_to_date('#{r[0]}', '%d.%m.%Y'),#{r[1]})" }.join(",")
  query = "insert into px (day, value) values #{values};"
  result = db.query(query)
  log.debug("New PX records loaded")
end

log.info("PX extract successfully finished")