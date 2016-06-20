require 'rubygems'
require 'mysql2'
require_relative 'configuration'
require_relative 'google_connector'


WORKSHEET_NAMES = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC']


def load_versions(db)
  versions = []
  query = "select name, id from tr_version"
  result = db.query(query)
  result.each { |x| versions << x['name'] << x['id'] }
  Hash[*versions]
end

def load_categories(db)
  categories = []
  query = "select name, id from tr_category"
  result = db.query(query)
  puts result
  result.each { |x| categories << x['name'] << x['id'] }
  Hash[*categories]
end


def load_accounts(db)
  accounts = []
  query = "select name, id from tr_account"
  result = db.query(query)
  result.each { |x| accounts << x['name'] << x['id'] }
  Hash[*accounts]
end


def get_accounts(spreadsheet)
  accounts = []
  ws = spreadsheet.worksheet_by_title('Metrics')
  
  # load revenue accounts
  for r in 3..14 do
    accounts << [ws[r,1], ws[r,2]] unless ws[r,1].empty?
  end
  
  # load cost accounts
  for r in 18..35 do
    accounts << [ws[r,1], ws[r,2]] unless ws[r,1].empty?
  end

  accounts
end


def get_year(spreadsheet)
  ws = spreadsheet.worksheet_by_title('Metrics')
  year = ws[3,11].to_i
  year
end


def get_transactions(spreadsheet)
  transactions = []
  year = get_year(spreadsheet)
  
  # get transactions in each month
  for month in 1..12 do
  
    # load proper month tab
    ws = spreadsheet.worksheet_by_title(WORKSHEET_NAMES[month - 1])

	# get revenues
    r = 2
    while ! ws[r,1].empty?
      # id, date, account, amount, description
      transactions << ["#{year}_#{month}_R_#{r}", Date.new(year, month, 1), ws[r,1], ws[r,2].gsub(',','').to_i, ws[r,3].gsub("'","''")]
      r = r + 1
    end
    
    # get costs
    r = 2
    while ! ws[r,5].empty?
      # id, date, account, amount, description
      transactions << ["#{year}_#{month}_C_#{r}", Date.new(year, month, 1), ws[r,5], ws[r,6].gsub(',','').to_i * -1, ws[r,7].gsub("'","''")]
      r = r + 1
    end
 
  end
  
  transactions
end


def save_new_accounts(spreadsheet, db)

  # get accounts from the sheet
  accounts = get_accounts(spreadsheet)
  # get existing accounts from db
  existing_accounts_h = load_accounts(db)
  
  # find accounts missing in db
  account_names = accounts.map { |a| a[0] }
  existing_account_names = existing_accounts_h.keys
  new_account_names = account_names - existing_account_names

  # create array of account name + category id
  accounts_h = Hash[*accounts.flatten]
  categories_h = load_categories(db)
  
  new_accounts = []
  new_account_names.each do |account_name|
     category_name = accounts_h[account_name]
     category_id = categories_h[category_name]
    
     new_accounts << [account_name, category_id]
  end
  
  # insert new accounts into db
  if new_accounts.count > 0
    values = new_accounts.map { |a| "('#{a[0]}', #{a[1]})"}.join(',')
    query = "INSERT INTO tr_account(name, category_id) VALUES #{values}"
    db.query(query)
  end

end


def get_balance(spreadsheet)  
  ws = spreadsheet.worksheet_by_title('Metrics')
  r = 2
  balance = nil
  
  while balance.nil? && r < ws.num_rows do
    if ws[r,10] == "Balance BOY" then
      balance = ws[r,11].gsub(',','').to_i
    end
    r += 1
  end
  
  balance
end


def load_cf_sheet(session, sheet_key, db)
  puts "Processing CF spreadsheet #{sheet_key}"
  
  spreadsheet = session.spreadsheet_by_key(sheet_key)

  save_new_accounts(spreadsheet, db)
 

  ### save transactions (reality)
  transactions = get_transactions(spreadsheet)
  
  # translate transaction account name to id
  accounts_h = load_accounts(db)
  transactions.each { |t| t[2] = accounts_h[t[2]] }
  
  # delete transactions in processing year
  year = get_year(spreadsheet)
  puts "Loading year #{year} transactions"
  query_delete = "DELETE FROM transaction WHERE year(t_date) = #{year};"

  # add version = reality
  versions = load_versions(db)
  reality_id = versions["Reality"]

  if (transactions.empty?) then
    puts "No transactions found for year #{year}"
  else

    # insert transactions
    values = transactions.map { |t| "('#{t[0]}', '#{t[1]}', #{t[2]}, #{t[3]}, '#{t[4]}', #{reality_id})" }.join(', ')
    query_insert = "INSERT INTO transaction (id, t_date, account_id, amount, note, version_id) VALUES #{values}"
  
    db.query("START TRANSACTION;")
    db.query(query_delete)
    db.query(query_insert)
    db.query("COMMIT;")
  
    puts "Transactions saved"
  end
  
  
  ### save forecast
  forecast_id = versions["Forecast"]
  values = []
  ws_forecast = spreadsheet.worksheet_by_title('Forecast')
  ws_reality = spreadsheet.worksheet_by_title('Report')

  if ! ws_forecast.nil?
    for c in (Time.now.month + 1)..13 do
      month = c - 1
      t_date = Date.new(year, month, 1)
    
      for r in 8..19 do
        if ! ws_forecast[r,1].empty?
          amount_reality = ws_reality[r,c].gsub(',','').to_i
          amount = ws_forecast[r,c].gsub(',','').to_i - amount_reality
          if (amount > 0)
            account_name = ws_forecast[r,1]
            account_id = accounts_h[account_name]
            id = "#{year}_#{month}_R_#{r}_F"
            values << "('#{id}', '#{t_date}', #{account_id}, #{amount}, '', #{forecast_id})"
          end  
        end
      end
    
      for r in 23..40 do
        if ! ws_forecast[r,1].empty?
          amount_reality = ws_reality[r,c].gsub(',','').to_i
          amount = amount_reality - ws_forecast[r,c].gsub(',','').to_i
          if (amount < 0)
            account_name = ws_forecast[r,1]
            account_id = accounts_h[account_name]
            id = "#{year}_#{month}_C_#{r}_F"
            values << "('#{id}', '#{t_date}', #{account_id}, #{amount}, '', #{forecast_id})"
          end
        end
      end
    end
  
    if ! values.empty?
      values = values.join(', ')
      query = "INSERT INTO transaction (id, t_date, account_id, amount, note, version_id) VALUES #{values}"
      db.query(query)
  
      puts "Forecast saved"
    else
      puts "No forecast to be saved"
    end
  end

  
  ### save balance if set
  balance_boy = get_balance(spreadsheet)
  if ! balance_boy.nil? then
    query_delete = "DELETE FROM balance WHERE b_date = '#{Date.new(year,1,1)}'"
    query_insert = "INSERT INTO balance (b_date, balance) VALUES ('#{Date.new(year,1,1)}', #{balance_boy})"

    db.query("START TRANSACTION;")
    db.query(query_delete)
    db.query(query_insert)  
    db.query("COMMIT;")
    
    puts "Balance saved"
  else
    puts "Balance not found"
  end
 
end



# create Google session
gc = GoogleConnector.new
session = gc.get_session(Configuration['client_id'], Configuration['client_secret'])
sheets = Configuration.get_array('cf_sheets')

# connect to db
begin
  db = Mysql2::Client.new(:host => Configuration['db_host'], :database => Configuration['db_name'], :username => Configuration['db_user'], :password => Configuration['db_password'], :flags => Mysql2::Client::MULTI_STATEMENTS)
rescue
  puts "Unable to connect to the database"
  exit 1;
end

# load CF sheets - all or the last one
if Configuration['extract_last_cf_sheet_only'] == 'true'
  load_cf_sheet(session, sheets.last, db)
else
  sheets.each { |sheet_key| load_cf_sheet(session, sheet_key, db) }
end