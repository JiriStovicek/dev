require 'net/http'
require 'json'
require_relative 'configuration'
require 'mysql2'


MIN_DATE = Date.new(2007,1,1)
BASE_CURRENCY = "CZK"
CURRENCIES = ["EUR", "USD", "GBP"]


# connect to db
begin
  db = Mysql2::Client.new(:host => Configuration['db_host'], :database => Configuration['db_name'], :username => Configuration['db_user'], :password => Configuration['db_password'], :flags => Mysql2::Client::MULTI_STATEMENTS)
rescue
  puts "Unable to connect to the database"
  exit 1;
end


# find last record
query = "select max(b_date) maxdate from exchange_rate"
result = db.query(query)
row = result.first
last_date = row['maxdate']

if (last_date.nil?)
  day = MIN_DATE
  puts "No exchange rate found in database."
else
  day = last_date + 1
  puts "Last exchange rate found: #{last_date}"
end


# load missing exchange rates till yesterday
while (day < Date.today) do

  url = "http://api.fixer.io/#{day.strftime("%F")}/?base=#{BASE_CURRENCY}"
  puts "Processing #{url}"
  uri = URI(url)
  response = Net::HTTP.get(uri)
  exch_hash = JSON.parse(response)

  values = CURRENCIES.map { |c| "('#{day}', '#{c}', #{1/exch_hash['rates'][c]})" }.join(', ')
  values += ", ('#{day}', '#{BASE_CURRENCY}', 1)"
  
  query = "insert into exchange_rate (b_date, currency, price) values #{values}"
  result = db.query(query)

  day += 1

end