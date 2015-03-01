require 'rubygems'
require 'google_drive'


class GoogleConnector


  def initialize
    @refresh_token_file = 'refresh_token'
    @app_name = 'Secretary'
    @app_version = '1.0.0'
  end


  def get_session(client_id, client_secret)
    
    client = Google::APIClient.new(
      :application_name => app_name,
      :application_version => app_version
    )

    auth = client.authorization
    auth.client_id = client_id
    auth.client_secret = client_secret
    auth.scope =
      "https://www.googleapis.com/auth/drive " +
      "https://spreadsheets.google.com/feeds/"
    auth.redirect_uri = "urn:ietf:wg:oauth:2.0:oob"

    if (File.exists?(@refresh_token_file)) then
	  auth.refresh_token = File.read(@refresh_token_file)
    else
	  print("1. Open this page:\n%s\n\n" % auth.authorization_uri)
      print("2. Enter the authorization code shown in the page: ")
      auth.code = $stdin.gets.chomp
    end

    auth.fetch_access_token!
    
    File.write(@refresh_token_file, auth.refresh_token)

    session = GoogleDrive.login_with_oauth(auth.access_token)
    
    session
  end
  
    
end
