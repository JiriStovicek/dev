require 'rubygems'
require 'mysql2'
require_relative 'configuration'


# connect to db
begin
  db = Mysql2::Client.new(:host => Configuration['db_host'], :database => Configuration['db_name'], :username => Configuration['db_user'], :password => Configuration['db_password'], :flags => Mysql2::Client::MULTI_STATEMENTS)
rescue
  puts "Unable to connect to the database"
  exit 1;
end


# create table out_stock_analysis_month and fill id, date and price
file = File.open("transform_stock.sql", "rb")
query = file.read
db.query(query)
db.abandon_results!
  

# get date range
result = db.query("select b_date, stock_id, price from out_stock_analysis_month")
result.each { |row|
	puts row["price"].to_f
}