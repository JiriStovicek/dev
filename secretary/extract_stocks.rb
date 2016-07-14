require 'rubygems'
require 'mysql2'
require 'nokogiri'
require 'open-uri'
require_relative 'configuration'
require_relative 'google_connector'


def load_tickers(db)
  tickers = []
  query = "select ticker, id from stock"
  result = db.query(query)
  result.each { |x| tickers << x['ticker'] << x['id'] }
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


def extract_stock_details(spreadsheet, db)
  # update share count and currency of stocks
  ws = spreadsheet.worksheet_by_title('Analysis')

  r = 2
  while ! ws[r,1].empty? do
  
    shares = ws[r,15].empty? ? 'NULL' : ws[r,15].gsub(',','')
    report_currency = ws[r,14].empty? ? 'NULL' : "'#{ws[r,14]}'"

    query = "UPDATE stock SET report_currency = #{report_currency}, shares = #{shares} WHERE ticker = '#{ws[r,1]}'" #ticker, currency, shares
    db.query(query)
    r += 1
  end
  
end


def extract_trades(spreadsheet, db)
  # get trades
  ws = spreadsheet.worksheet_by_title('Trades')
  trades = []
  r = 3
  while ! ws[r,1].empty? do
    # ticker, buy_date, buy_price, quantity, buy_charge, sell_date, sell_price, sell_charge
    trades << [ws[r,1], ws[r,2], ws[r,3].gsub(',',''), ws[r,4].gsub(',',''), ws[r,5].gsub(',','').to_f.round(2), ws[r,15], ws[r,16].gsub(',',''), ws[r,17].gsub(',','').to_f.round(2)]
    r += 1
  end
  
  # translate tickers to id
  tickers_h = load_tickers(db)
  trades.each { |t| t[0] = tickers_h[t[0]] }

  # save into db
  values = []  
  trades.each do |t| 
    if t[5].empty?  # not sold yet
      values << "(#{t[0]}, STR_TO_DATE('#{t[1]}', '%Y-%m-%d'), #{t[2]}, #{t[3]}, #{t[4]}, null, null, null)"
    else
      values << "(#{t[0]}, STR_TO_DATE('#{t[1]}', '%Y-%m-%d'), #{t[2]}, #{t[3]}, #{t[4]}, STR_TO_DATE('#{t[5]}', '%Y-%m-%d'), #{t[6]}, #{t[7]})"
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
    dividends << [ws[r,1], ws[r,2], ws[r,3], ws[r,4], ws[r,5], ws[r,6]] unless ws[r,1].empty?
    r += 1
  end

  # load existing tickers
  tickers_h = load_tickers(db)
  dividends.each { |t| t[0] = tickers_h[t[0]] }
  
  values = dividends.map { |d| "(#{d[0]}, STR_TO_DATE('#{d[1]}', '%Y-%m-%d'), #{d[2].gsub(',','')}, #{d[3].gsub(',','').to_f / 100}, #{d[4].gsub(',','')}, #{d[5].gsub(',','')})" }.join(',')
  query_delete = "DELETE FROM st_dividends"
  query_insert = "INSERT INTO st_dividends (stock_id, record_day, dividend_brutto, tax_rate, exchange_rate, dividend_netto_czk) VALUES #{values}"

  db.query("START TRANSACTION;")
  db.query(query_delete)
  db.query(query_insert)
  db.query("COMMIT;")
end


def extract_reports(spreadsheet, db)
  reports = []
  tickers_h = load_tickers(db)
  tickers_h.keys.each do |t|
  
    # open worksheet identified by each ticker  
    ws = spreadsheet.worksheet_by_title(t)
    if ws.nil?
      puts "Reports for #{t} not found"
    else
     
      # load reports of a single company
      r = 2
      while r <= ws.num_rows do
        # ticker, period, income, profit, assets, equity
        reports << [t, ws[r,1], ws[r,2], ws[r,3], ws[r,4], ws[r,5]] unless ws[r,1].empty?
        r += 1
      end
      
    end
  end
  
  values = reports.map do |r|
    # parse year
    period = r[1]
    year = period[0..3].to_i
    
    # parse period type and number
    periods_per_year = 1
    period_number = 1
    
    if period.length > 4
      if period[4] == 'Q'
        periods_per_year = 4
      elsif period[4] == 'H'
        periods_per_year = 2
      end
      
      period_number = period[5].to_i
    end
    
    date = Date.new(year,1,1) >> 12 * period_number / periods_per_year

    "(#{tickers_h[r[0]]}, '#{year}', '#{date}', #{periods_per_year}, #{period_number}, #{r[4].gsub(',','')}, #{r[5].gsub(',','')}, #{r[2].gsub(',','')}, #{r[3].gsub(',','')})"
  end
  
  values = values.join(',')
  
  query_delete = "DELETE FROM st_report"
  query_insert = "INSERT INTO st_report (stock_id, period_year, report_date, periods_per_year, period_number, assets, equity, income, profit) VALUES #{values}"

  db.query("START TRANSACTION;")
  db.query(query_delete)
  db.query(query_insert)
  db.query("COMMIT;")
  
end



# create Google session
gc = GoogleConnector.new
session = gc.get_session(Configuration['client_id'], Configuration['client_secret'])
spreadsheet = session.spreadsheet_by_key(Configuration['stock_sheet'])

# connect to db
begin
  db = Mysql2::Client.new(:host => Configuration['db_host'], :database => Configuration['db_name'], :username => Configuration['db_user'], :password => Configuration['db_password'], :flags => Mysql2::Client::MULTI_STATEMENTS)
rescue
  puts "Unable to connect to the database"
  exit 1;
end



extract_tickers(spreadsheet, db)
extract_stock_details(spreadsheet, db)
extract_trades(spreadsheet, db)
extract_dividends(spreadsheet, db)
extract_reports(spreadsheet, db)