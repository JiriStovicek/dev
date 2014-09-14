require 'rubygems'
require 'mysql'
require 'csv'
require 'open-uri'
require 'rubyXL'
require 'parseconfig'


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
query = "select max(day) from gdp"
result = db.query(query)
row = result.fetch_row()
last_date = row[0].nil? ? Date.parse(min_date) : Date.parse(row[0])


# download gdp quarterly
File.open('data/gdp.xls', "wb") do |file|
  file.write open('http://www.czso.cz/csu/csu.nsf/i/tab_vs/$File/tab_vs_2q14r.xlsx').read
end


# filter data rows
workbook = RubyXL::Parser.parse('data/gdp.xls').worksheets
rows = workbook[0].extract_data.to_a 
rows = rows.select { |r| /Q[1-4]/.match(r[1]) && ! r[2].to_s.empty?}


# get clean values
year = 0
records = []
last_day_of_quarter = ["-03-31", "-06-30", "-09-30", "-12-31"]

rows.each do |r|

  # fill empty years
  unless r[0].to_s.empty?
    year = r[0]
  end

  # assemble date
  quarter = r[1].to_s[1].to_i
  day = Date.parse(year.to_s + last_day_of_quarter[quarter - 1])

  records << [day, r[2]]
end


# find new records
new_records = records.select { |r| r[0] > last_date }
puts "New records found: #{new_records.length}"


# load new records
if (new_records.length > 0)
  values = new_records.map { |r| "(str_to_date('#{r[0]}','%Y-%m-%d'),#{r[1]})" }.join(',')
  query = "insert into gdp (day, value) values #{values}"
  result = db.query(query)
  puts result
end

