#!/bin/bash

cd /Users/Jirka/Dev/secretary/


ruby update_cf_forecast.rb
ruby extract_cf.rb

ruby update_stock_price.rb
ruby update_exchange.rb
ruby extract_stocks.rb
ruby extract_stock_price.rb
ruby extract_exchange.rb 

ruby transform.rb
