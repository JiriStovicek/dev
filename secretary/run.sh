#!/bin/bash

cd /Users/Jirka/Dev/secretary/


ruby update_cf_forecast.rb
ruby extract_cf.rb
ruby transfrom_cf.rb

ruby extract_stocks.rb
ruby extract_stock_price.rb
