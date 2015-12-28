require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'google_drive'
require_relative 'configuration'
require_relative 'google_connector'


names = {
  "ČEZ" => "CEZ",
  "E4U" => "E4U",
  "ERSTE GROUP BANK AG" => "ERBAG",
  "FORTUNA" => "FOREG",
  "KOMERČNÍ BANKA" => "KOMB",
  "PEGAS NONWOVENS SA" => "PEGAS",
  "PHILIP MORRIS ČR" => "TABAK",
  "VIG" => "VIG",
  "STOCK SPIRITS GROUP" => "STOCK",
  "KOFOLA ČS" => "KOFOL"}
  


# parse data from web
page = Nokogiri::HTML(open("http://www.akcie.cz/kurzy-cz/bcpp-vse"))

rows = page.css('tbody').css('tr').select { |i| names.keys.include? i.css('td').css('a').text }

if (rows.length == 0)
  puts "No prices found on web"
  exit 1
end

values = rows.map { |r| [names[r.css('td').css('a').text], r.css('td')[2].text.gsub(' ','').gsub(',','.').to_f]  }

# connect to the spreadsheet
gc = GoogleConnector.new
session = gc.get_session(Configuration['client_id'], Configuration['client_secret'])
ws = session.spreadsheet_by_key("0AvJP0_lCRv_udGk2bkZsQ0hydnJxWTh1Q1hIbHdXQUE").worksheets[0]

# create price hash
prices = values.inject(Hash.new{ |h,k| h[k]=[] }) { |h,(k,v)| h[k] << v; h }

i_row = 2
while ! ws[i_row, 1].empty? do
  
  ticker = ws[i_row, 1]
  price_a = prices[ticker]
  price = price_a[0]
  
  # set new price
  ws[i_row, 12] = price

  i_row += 1
end

ws.synchronize()
