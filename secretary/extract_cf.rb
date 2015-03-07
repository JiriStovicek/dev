require 'rubygems'
require 'mysql'
require_relative 'configuration'
require_relative 'google_connector'


WORKSHEET_NAMES = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC']


def load_categories(db)
  categories = []
  query = "select name, id from tr_category"
  result = db.query(query)
  result.each { |x| categories << x[0] << x[1] }
  Hash[*categories]
end


def load_accounts(db)
  accounts = []
  query = "select name, id from tr_account"
  result = db.query(query)
  result.each { |x| accounts << x[0] << x[1] }
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
      transactions << [Date.new(year, month, 1), ws[r,1], ws[r,2].gsub(',','').to_i, ws[r,3]]
      r = r + 1
    end
    
    # get costs
    r = 2
    while ! ws[r,5].empty?  
      transactions << [Date.new(year, month, 1), ws[r,5], ws[r,6].gsub(',','').to_i, ws[r,7]]
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


def load_cf_sheet(session, sheet_key, db)

  spreadsheet = session.spreadsheet_by_key(sheet_key)

  save_new_accounts(spreadsheet, db)
 
  # load transactions
  transactions = get_transactions(spreadsheet)
  
  # translate transaction account name to id
  accounts_h = load_accounts(db)
  transactions.each { |t| t[1] = accounts_h[t[1]] }
  
  # delete transactions in processing year
  year = get_year(spreadsheet)
  query_delete = "DELETE FROM transaction WHERE year(t_date) = #{year};"
  
  # insert transactions
  values = transactions.map { |t| "('#{t[0]}', #{t[1]}, #{t[2]}, '#{t[3]}')" }.join(', ')
  query_insert = "INSERT INTO transaction (t_date, account_id, amount, note) VALUES #{values}"
  

  db.query("START TRANSACTION;")
  db.query(query_delete)
  db.query(query_insert)  
  db.query("COMMIT;")
 
end



# create Google session
gc = GoogleConnector.new
session = gc.get_session(Configuration['client_id'], Configuration['client_secret'])
sheets = Configuration.get_array('cf_sheets')

# connect to db
begin
  db = Mysql.new(Configuration['db_host'], Configuration['db_user'], Configuration['db_password'], Configuration['db_name'])
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