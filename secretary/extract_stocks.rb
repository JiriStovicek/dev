require 'rubygems'
require 'mysql'
require 'nokogiri'
require 'open-uri'
require_relative 'configuration'
require_relative 'google_connector'


def load_tickers(db)
  tickers = []
  query = "select ticker, id from stock"
  result = db.query(query)
  result.each { |x| tickers << x[0] << x[1] }
  Hash[*tickers]
end


def extract_tickers(spreadsheet, db)
  # get tickers in spreadsheet
  ws = spreadsheet.worksheet_by_title('Analysis')
  tickers = []
  r = 2
  while ! ws[r,1].empty? do
    tickers << ws[r,1]
    r += 1
  end

  # load existing tickers
  existing_tickers_h = load_tickers(db)

  # save new tickers to db
  new_tickers = tickers - existing_tickers_h.keys

  if (new_tickers.count > 0)
    values = new_tickers.map { |t| "('#{t}')" }.join(',')
    query = "INSERT INTO stock (ticker) VALUES #{values}"
    db.query(query)
  end
end


def extract_trades(spreadsheet, db)
  # get trades
  ws = spreadsheet.worksheet_by_title('Trades')
  trades = []
  r = 3
  while ! ws[r,1].empty? do
    # ticker, buy_date, buy_price, quantity, buy_charge, sell_date, sell_price, sell_charge
    trades << [ws[r,1], ws[r,2], ws[r,3], ws[r,4], ws[r,5].to_f.round(2), ws[r,15], ws[r,16], ws[r,17].to_f.round(2)]
    r += 1
  end
  
  # translate tickers to id
  tickers_h = load_tickers(db)
  trades.each { |t| t[0] = tickers_h[t[0]] }

  # save into db
  values = []  
  trades.each do |t| 
    if t[5].empty?  # not sold yet
      values << "(#{t[0]}, STR_TO_DATE('#{t[1]}', '%m/%d/%Y'), #{t[2]}, #{t[3]}, #{t[4]}, null, null, null)"
    else
      values << "(#{t[0]}, STR_TO_DATE('#{t[1]}', '%m/%d/%Y'), #{t[2]}, #{t[3]}, #{t[4]}, STR_TO_DATE('#{t[5]}', '%m/%d/%Y'), #{t[6]}, #{t[7]})"
    end
  end
  values = values.join(',')

  query_delete = "DELETE FROM st_trades;"
  query_insert = "INSERT INTO st_trades (stock_id, buy_date, buy_price, quantity, buy_charge, sell_date, sell_price, sell_charge) VALUES #{values};"

  db.query("START TRANSACTION;")
  db.query(query_delete)
  db.query(query_insert)  
  db.query("COMMIT;")
end


def extract_dividends(spreadsheet, db)
  # get tickers in spreadsheet
  ws = spreadsheet.worksheet_by_title('Dividends')
  dividends = []
  r = 2
  while r <= ws.num_rows do
    # ticker, record_day, dividend_brutto, dividend_netto
    dividends << [ws[r,1], ws[r,2], ws[r,3], ws[r,4]] unless ws[r,1].empty?
    r += 1
  end

  # load existing tickers
  tickers_h = load_tickers(db)
  dividends.each { |t| t[0] = tickers_h[t[0]] }
  
  values = dividends.map { |d| "(#{d[0]}, STR_TO_DATE('#{d[1]}', '%m/%d/%Y'), #{d[2]}, #{d[3]})" }.join(',')
  query_delete = "DELETE FROM st_dividends"
  query_insert = "INSERT INTO st_dividends (stock_id, record_day, dividend_brutto, dividend_netto) VALUES #{values}"
  
  puts db.query(query_delete)
  puts db.query(query_insert)
end



# create Google session
gc = GoogleConnector.new
session = gc.get_session(Configuration['client_id'], Configuration['client_secret'])
spreadsheet = session.spreadsheet_by_key(Configuration['stock_sheet'])

# connect to db
begin
  db = Mysql.new(Configuration['db_host'], Configuration['db_user'], Configuration['db_password'], Configuration['db_name'])
rescue
  puts "Unable to connect to the database"
  exit 1;
end



#extract_tickers(spreadsheet, db)
#extract_trades(spreadsheet, db)
extract_dividends(spreadsheet, db)
# extract company repords