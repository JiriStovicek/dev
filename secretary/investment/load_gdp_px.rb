require 'rubygems'
require 'parseconfig'
require 'mysql'
require 'google_drive'
require 'date'


# load configuration
config = ParseConfig.new('invest.cfg')
db_host = config['db_host']
db_user = config['db_user']
db_password = config['db_password']
db_name = config['db_name']
mysql_dir = config['mysql_dir']


# connect to the report
session = GoogleDrive.login("jiri.stovicek@gmail.com", "Ein8stein")
ws = session.spreadsheet_by_key("1QhFgpXRHVqEbOe3nZqtMk_SYPYUFWr5gu211fBrC6VQ").worksheets[1]

# find last row
i_row = 1
while ws[i_row, 1] != ''
  i_row = i_row + 1
end
last_day = Date.strptime(ws[i_row - 1, 1], '%m/%d/%Y')


# connect to db
begin
  db = Mysql.new(db_host, db_user, db_password, db_name)
rescue
  puts "ERROR - Unable to connect to the data base"
  exit 1;
end


# upload new data to spreadsheet
query = "select day, px_value, gdp_value from ( select px.day, px.value px_value, gdp.value / 1000 gdp_value from px left outer join gdp on gdp.day = px.day union select gdp.day, px.value px_value, gdp.value / 1000 gdp_value from gdp left outer join px on gdp.day = px.day where px.value is null) temp where day > '#{last_day.strftime('%Y-%m-%d')}' order by day"  # full outer join of px and gdp
result = db.query(query)
result.each do |x|
  ws[i_row, 1] = x[0]
  ws[i_row, 2] = x[1]
  ws[i_row, 3] = x[2]
  i_row = i_row + 1
end

ws.synchronize()