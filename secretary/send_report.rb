require 'rubygems'
require 'mail'
require 'logger'
require_relative 'configuration'


# start logging
log = Logger.new(Configuration['log_file'])
log.debug("Report creating started")


# send the report via email
mail = Mail.new do
  from     Configuration['reporting_sender']
  to       Configuration['reporting_recepient']
  subject  'Investment Report'
  body     "Here you are. \n -- Ruby"
  add_file :filename => 'investment.pdf', :content => File.read('data/investment.pdf')
end
mail.delivery_method :sendmail
mail.deliver!


log.info("Report sent to #{Configuration['reporting_recepient']}")