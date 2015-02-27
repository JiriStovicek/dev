require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'google_drive'
require_relative 'configuration'


names = {
  "ČEZ" => "CEZ",
  "E4U" => "E4U",
  "ERSTE GROUP BANK AG" => "ERBAG",
  "FORTUNA" => "FOREG",
  "KOMERČNÍ BANKA" => "KOMB",
  "PEGAS NONWOVENS SA" => "PEGAS",
  "PHILIP MORRIS ČR" => "TABAK",
  "VIG" => "VIG",
  "STOCK SPIRITS GROUP" => "STOCK"}
  


# parse data from web
page = Nokogiri::HTML(open("http://www.akcie.cz/kurzy-cz/bcpp-vse"))

rows = page.css('tbody').css('tr').select { |i| names.keys.include? i.css('td').css('a').text }

if (rows.length == 0)
  log.error("No prices found on web")
  exit 1
end

values = rows.map { |r| [names[r.css('td').css('a').text], r.css('td')[2].text.gsub(' ','').gsub(',','.').to_f]  }


# Authorize with OAuth and gets an access token.
client = Google::APIClient.new(
  :application_name => 'Secretary',
  :application_version => '1.0.0'
)

auth = client.authorization
auth.client_id = "1051680518002-9hobo0bdki25md0dfojj488s8ja581bk.apps.googleusercontent.com"
auth.client_secret = "-HBKoYLC-7nr93_eB9O5Nb49"
auth.scope =
    "https://www.googleapis.com/auth/drive " +
    "https://spreadsheets.google.com/feeds/"
auth.redirect_uri = "urn:ietf:wg:oauth:2.0:oob"

if (File.exists?('refresh_token')) then
	auth.refresh_token = File.read('refresh_token')
else
	print("1. Open this page:\n%s\n\n" % auth.authorization_uri)
	print("2. Enter the authorization code shown in the page: ")
	auth.code = $stdin.gets.chomp
end

auth.fetch_access_token!
File.write('refresh_token', auth.refresh_token)


# Create a session.
session = GoogleDrive.login_with_oauth(auth.access_token)


# connect to the spreadsheet
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