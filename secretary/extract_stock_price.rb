require 'rubygems'
require 'mysql2'
require 'nokogiri'
require 'open-uri'
require_relative 'configuration'


MIN_DATE = Date.new(2007,1,1)


def load_tickers(db)
  tickers = []
  query = "select ticker, id from stock"
  result = db.query(query)
  result.each { |x| tickers << x['ticker'] << x['id'] }
  Hash[*tickers]
end


# connect to db
begin
  db = Mysql2::Client.new(:host => Configuration['db_host'], :database => Configuration['db_name'], :username => Configuration['db_user'], :password => Configuration['db_password'], :flags => Mysql2::Client::MULTI_STATEMENTS)
rescue
  puts "Unable to connect to the database"
  exit 1;
end


# find last record
query = "select max(b_date) maxdate from st_price"
result = db.query(query)
row = result.first
last_date = row['maxdate'].nil? ? MIN_DATE : row['maxdate']
puts "Last stock record found: #{last_date}"


# load missing days till yesterday
tickers = load_tickers(db)
tickers_with_prep = tickers.keys.map { |t| "BAA#{t}"}

day = last_date + 1
while (day < Date.today) do

  url = "http://www.akcie.cz/kurzovni-listek/prazska-burza?cas=#{day.strftime('%d.%m.%Y')}"
  puts "Processing stock page: #{url}"
  page = Nokogiri::HTML(open(url))

  rows = page.css('tbody').css('tr').select { |i| tickers_with_prep.include?( i.css('td')[1].text ) }


  if (rows.length > 0)
    values = rows.map { |r| [r.css('td')[1].text, r.css('td')[3].text.gsub(' ','').gsub(',','.').to_f] }
    values = values.map { |r| "('#{day}', #{tickers[r[0].to_s[3,r[0].to_s.length-1]]}, #{r[1]})" }.join(',')
    
    query = "insert into st_price (b_date, stock_id, price) values #{values}"
    result = db.query(query)

  end

  day += 1

end