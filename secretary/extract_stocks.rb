require 'rubygems'
require 'mysql'
require 'nokogiri'
require 'open-uri'
require_relative 'configuration'


TICKERS = ['BAACEZ', 'BAAEFORU', 'BAAERGAB', 'BAAFOREG', 'BAAKOMB', 'BAATELEC', 'BAAPEGAS', 'BAATABAK', 'BAAVIG']


# connect to db
begin
  db = Mysql.new(Configuration['db_host'], Configuration['db_user'], Configuration['db_password'], Configuration['db_name'])
rescue
  puts "ERROR - Unable to connect to the database"
  exit 1;
end


# find last record
query = "select max(day) from stocks"
result = db.query(query)
row = result.fetch_row()
last_date = row[0].nil? ? Date.parse(min_date) : Date.parse(row[0])


# load missing days till yesterday
day = last_date + 1
while (day < Date.today) do

  url = "http://www.akcie.cz/kurzovni-listek/prazska-burza?cas=#{day.strftime('%d.%m.%Y')}"
  page = Nokogiri::HTML(open(url))

  rows = page.css('tbody').css('tr').select { |i| TICKERS.include?( i.css('td')[1].text ) }

  if (rows.length > 0)
    values = rows.map { |r| [r.css('td')[1].text, r.css('td')[3].text.gsub(' ','').gsub(',','.').to_f] }
    values = values.map { |r| "('#{day}', '#{r[0]}', #{r[1]})" }.join(',')

    query = "insert into stocks (day, ticker, price) values #{values}"
    result = db.query(query)
    puts day
  end

  day += 1

end