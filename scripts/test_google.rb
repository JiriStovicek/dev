require 'rubygems'
require 'google-search'
require_relative 'configuration'
require 'open-uri'


sites = {
#  "BAACEZ" => "www.cez.cz",
#  "BAAEFORU" => "www.e4u.cz",
#  "BAAERGAB" => "http://www.erstegroup.com/",
#  "BAAFOREG" => "http://www.fortunagroup.eu/",
#  "BAAKOMB" => "www.kb.cz",
#  "BAAPEGAS" => "www.pegas.cz",
#  "BAATABAK" => "www.pmi.com",
  "BAAVIG" => "www.vig.com"}

tickers = Configuration.get_array('tickers')
quarters = ["Q1", "H1", "Q3", ""]


#Google::Search::Web.new(:query => 'site:http://www.cez.cz filetype:pdf 2012 H1 financial results').each do |item|
#  puts item.uri
#end

tickers.each do |ticker|
  year_min = 2013
  quarter_min = 1
  year_max = 2014
  quarter_max = 2
  
  y = year_min
  q = quarter_min
  
  begin
    
    if sites.keys.include? ticker then
      query = "site:#{sites[ticker]} filetype:pdf #{y} #{quarters[q - 1]} financial results"
      result = Google::Search::Web.new(:query => query).first
      
      if ( ! result.nil?) then
        uri = result.uri
        puts uri
        
        open("data/#{ticker}_#{y}_Q#{q}.pdf", 'wb') do |file|
          file << open(uri).read
        end
        
      end
    end
        
    q = (q % 4) + 1
    if (q == 1) then y += 1 end

  end until y == year_max && q == quarter_max
end