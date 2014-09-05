require 'rubygems'
require 'mysql'
require 'parseconfig'


# load configuration
config = ParseConfig.new('extractor.cfg')
db_host = config['db_host']
db_user = config['db_user']
db_password = config['db_password']
db_name = config['db_name']


db = Mysql.new(db_host, db_user, db_password, db_name)


#query = "select day, ticker, price from stocks"
query = "select px.day, gdp.value, px.value from gdp right outer join px on gdp.day = px.day"

result = db.query(query)
result.each {|x| puts x.join(',')}