require 'sinatra' 		# Our handy lightweight webserver
require 'rest-client' 	# Used for authentication with the GitHub OAuth API
require 'json' 			# Used to parse the JSON response from the GitHub OAuth API
require 'octokit' 		# Used to retrieve user data after authentication

=begin
[ !IMPORTANT! ]
In production, the CLIENT_ID & CLIENT_SECRET (below) should never be
hard-coded or exposed. Instead, you should export environment
variables for these values. NEVER check your CLIENT_ID or CLIENT_SECRET
into a git repository that is or may become public.

In production, these values should be accessed as environement variables
like this: CLIENT_ID = ENV['CLIENT_ID']
=end

CLIENT_ID = '<YOUR_CLIENT_ID'
CLIENT_SECRET = '<YOUR_CLIENT_SECRET>'


# This is our login page that loads up our index.erb view
# and brings our CLIEND_ID along for the ride.
get '/' do
  erb :index, :locals => {:client_id => CLIENT_ID}
end


# This is our 'logged-in' view, displaying profile.erb after the user has
# authenticated with GitHub (this is the 'callback URL' we entered when
# registering our OAUth Application on GitHub.com).
get '/profile' do
	erb :profile
end