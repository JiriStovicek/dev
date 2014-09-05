require 'rubygems'
require 'mysql'

db = Mysql.new('sql5.freesqldatabase.com', 'sql551396', 'aG5*lH7%', 'sql551396')

file = File.open("sql/init_db.sql")
query = ""
file.each {|line|
  query << line
}

result = db.query(query)
puts result
