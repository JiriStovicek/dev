require 'rubygems'
require 'mysql'
require 'csv'
require "open-uri"
require 'spreadsheet'


# download px price list
File.open('data/makro.xls', "wb") do |file|
  file.write open('http://www.czso.cz/csu/redakce.nsf/i/cr:_makroekonomicke_udaje/$File/HLMAKRO.xls').read
end


rows = Array.new
book = Spreadsheet.open('data/makro.xls')
sheet1 = book.worksheet('ČR') # can use an index or worksheet name
sheet1.each do |r|
  rows.push(r.to_a())
end

i_years = 5
r_years = rows[i_years - 1]
r_gdp = rows.select { |r| r[0] == "HDP" }

puts r_years.join(',')
puts r_gdp.join(',')
