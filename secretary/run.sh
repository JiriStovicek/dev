#!/bin/bash

cd /Users/Jirka/Dev/secretary/


ruby extract_gdp.rb
ruby extract_px.rb
ruby extract_stocks.rb

ruby create_report.rb

ruby send_report.rb
