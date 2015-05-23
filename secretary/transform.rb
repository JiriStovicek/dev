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


queries = ["transform_cf.sql", "transform_portfolio.sql"]

queries.each do |q|

  file = File.open(q, "rb")
  query = file.read
  db.query(query)

  db.abandon_results!
end