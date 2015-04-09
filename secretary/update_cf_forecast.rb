require 'rubygems'
require 'google_drive'
require_relative 'configuration'
require_relative 'google_connector'


# get current sheet key
sheet_key = Configuration.get_array('cf_sheets').last

# connect to the spreadsheet
gc = GoogleConnector.new
session = gc.get_session(Configuration['client_id'], Configuration['client_secret'])
spreadsheet = session.spreadsheet_by_key(sheet_key)

ws_report = spreadsheet.worksheet_by_title('Report')
ws_forecast = spreadsheet.worksheet_by_title('Forecast')

for month in 1..Time.now.month do
  c = month + 1
  
  # update revenes (rows 8..19) and costs (rows 23..40)
  ((8..19).to_a + (23..40).to_a).each do |r|
  
    val_report = ws_report[r,c].gsub(',','').to_i
    val_forecast = ws_forecast[r,c].gsub(',','').to_i
    
    # update past months and current month
    if ((month < Time.now.month and val_forecast != val_report) or (month == Time.now.month and val_forecast < val_report))
      ws_forecast[r,c] = val_report
    end
      
  end
  
end

ws_forecast.synchronize()