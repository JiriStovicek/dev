require 'rubygems'
require 'mysql'
require 'nokogiri'
require 'open-uri'
require 'parseconfig'


tickers = ['BAACEZ', 'BAAEFORU', 'BAAERGAB', 'BAAFOREG', 'BAAKOMB', 'BAATELEC', 'BAAPEGAS', 'BAATABAK', 'BAAVIG']

# load configuration
config = ParseConfig.new('invest.cfg')
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
query = "select max(day) from stocks"
result = db.query(query)
row = result.fetch_row()
last_date = row[0].nil? ? Date.parse(min_date) : Date.parse(row[0])


# load missing days till yesterday
day = last_date + 1
while (day < Date.today) do

  url = "http://www.akcie.cz/kurzovni-listek/prazska-burza?cas=#{day.strftime('%d.%m.%Y')}"
  page = Nokogiri::HTML(open(url))

  rows = page.css('tbody').css('tr').select { |i| tickers.include?( i.css('td')[1].text ) }

  if (rows.length > 0)
    values = rows.map { |r| [r.css('td')[1].text, r.css('td')[3].text.gsub(' ','').gsub(',','.').to_f] }
    values = values.map { |r| "('#{day}', '#{r[0]}', #{r[1]})" }.join(',')

    query = "insert into stocks (day, ticker, price) values #{values}"
    result = db.query(query)
    puts day
  end

  day += 1

end