require 'rubygems'
require 'parseconfig'
require 'google_drive'
require 'mail'


# download report to pdf
session = GoogleDrive.login("jiri.stovicek@gmail.com", "Ein8stein")
session.spreadsheet_by_key("1QhFgpXRHVqEbOe3nZqtMk_SYPYUFWr5gu211fBrC6VQ").export_as_file('data/invest.pdf', 'pdf', 1064105070)


# send the report via email
mail = Mail.new do
  from     'ruby@secretary.com'
  to       'jiri.stovicek@gmail.com'
  subject  'Invest Report'
  body     "Here you are. \n -- Ruby"
  add_file :filename => 'invest.pdf', :content => File.read('data/invest.pdf')
end
mail.delivery_method :sendmail
mail.deliver!