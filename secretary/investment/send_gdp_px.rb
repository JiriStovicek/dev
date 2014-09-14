require 'rubygems'
require 'parseconfig'
require 'google_drive'
require 'mail'


# load configuration
config = ParseConfig.new('../secretary.cfg')
reporting_sender = config['reporting_sender']
reporting_recepient = config['reporting_recepient']
gmail_login = config['gmail_login']
gmail_password = config['gmail_password']


# download report to pdf
session = GoogleDrive.login(gmail_login, gmail_password)
session.spreadsheet_by_key("1QhFgpXRHVqEbOe3nZqtMk_SYPYUFWr5gu211fBrC6VQ").export_as_file('data/investment.pdf', 'pdf', 1064105070)


# send the report via email
mail = Mail.new do
  from     reporting_sender
  to       reporting_recepient
  subject  'Investment Report'
  body     "Here you are. \n -- Ruby"
  add_file :filename => 'investment.pdf', :content => File.read('data/investment.pdf')
end
mail.delivery_method :sendmail
mail.deliver!