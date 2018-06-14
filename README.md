# GitHub OAuth Ruby Quickstart

[DEGW: An intro here motivating the problem you are trying to help solve. Explain (briefly) what an OAuth app is, and why you might want to build one. Why do we need a guide? Is it hard to do? (Narrator: In fact, it is hard.) ALso give a preview of what the reader can expect to have achieved by the end of the article.]

[DEGW: More thoughts. I am certainly guilty of this myself, but I am finding I dislike the word "user" to describe people who will be using your application. We should think about ways to avoid this word in our writing. It will not be easy.]

## About this Quickstart Guide
This is a quickstart guide to GitHub OAuth authentication using:
- Ruby
- The [Sinatra](http://sinatrarb.com) web framework
- [Octokit](https://github.com/octokit/octokit.rb) - a Ruby client for the GitHub [REST API](https://github.com.) (makes interacting with GitHub data easier)

To demonstrate the OAuth process, we're going to:
1) Set up a basic web server with Sinatra
2) Register a new OAuth Application on GitHub.com
3) Authenticate a user into our Sinatra app using GitHub's OAuth API
4) Use Octokit to retrieve this user's information from GitHub

### Prerequisites
If you haven't signed up for the [GitHub Developer Program](https://developer.github.com/program) yet, you'll need to do that before starting this guide.

[DEGW: Why? This hardly seems necessary—I don't think we have the right incentives set up to make this stick. Recommend removing for now.]

#### OAuth 101
TODO: Is this necessary / Appropriate? Perhaps include a high-level overview of the OAuth 'dance'?

## 1) Sinatra Webserver Setup
First, go ahead and clone the starter code from the [OAuth Ruby Quickstart Guide](https://github.com/github/OAuth-Ruby-Quickstart) repository.

This repository contains 3 files that we'll be working with:

`server.rb` - Our Sinatra webserver

`views/index.erb` - The webpage users will see before 'Signing in with GitHub'

`views/profile.erb` - The webpage users will see _after_ authenticating with GitHub OAuth. This page will display their profile photo, along with other user information

_P.S._([erb](https://ruby-doc.org/stdlib-2.5.1/libdoc/erb/rdoc/ERB.html) is a Ruby templating language which allows us to build HTML pages and pass in application data to be displayed on the page)


To fire up our webapp, open a terminal and run the following command from the project directory.
```
$ ruby server.rb 
```

You should see a message that **'Sinatra has taken the stage'**

![sinatra_on_stage](https://user-images.githubusercontent.com/3988879/40750699-5cb07faa-6425-11e8-829b-d2ffe7620871.png)

We can now visit [http://localhost:4567](http://localhost:4567) to see our webpage.

You should see something like this:

![localhost:4567](https://user-images.githubusercontent.com/3988879/40741163-fee7adca-6407-11e8-9465-9cbdb2072286.png)

Our Sinatra app is up and running, but clicking that green **Sign In** button won't work yet. First, we need to register a new GitHub OAuth Application.


## 2) Register a new GitHub OAuth Application
Head on over to your [Developer Settings](https://github.com/settings/developers) and register a new OAuth Application.

![screen shot 2018-05-25 at 4 23 36 pm](https://user-images.githubusercontent.com/3988879/40568485-0f8fb498-6038-11e8-8405-25142babaac8.png)


You'll find the following fields:
**Application name** - This must be unique among all GitHub OAuth Applications.
**Homepage URL** - If you don't have a homepage for your application yet, just use your GitHub profile: `https://github.com/<YOUR_USER_NAME>` (don't forget the `https://`).
**Application description** - Explain to future users what this OAuth Application is used for.
**Authorization callback URL** - GitHub needs to know where to redirect users after a successful OAuth authorization. For this app, the user should be redirected to the `/profile` view in our `server.rb` file. Since we're still working locally, we can actually use the localhost url from step #1: `http://localhost:4567/profile`.


## 3) Authenticate a User with GitHub’s OAuth API
Now for the fun stuff.

After registering your OAuth Application, you should see your Client ID and Client Secret. They'll look something like this:

![Client ID and Secret](https://user-images.githubusercontent.com/3988879/40741261-569e00d2-6408-11e8-96e4-3b454b5d7cbe.png)

Copy the Client ID and Client Secret into their respective places in the `server.rb` file.

Given the example above, the code would look like this:

![Client ID & Secret](https://user-images.githubusercontent.com/3988879/40741287-6c5267f6-6408-11e8-9d74-b5d1fe3f7232.png)

With that set up, we're ready to authenticate a user with GitHub's OAuth API.

With the Sinatra app running, go ahead and visit [localhost:4567](http://localhost:4567) again. This time, clicking the **Sign In with GitHub** button should take you to an authorization page:

![authorization](https://user-images.githubusercontent.com/3988879/40750372-4c5ae452-6424-11e8-8eda-67d03ca548fc.png)

This is where users grant your OAuth Application permission to access their data. As you can see, we're only requesting public data right now.

##### What happened here?
If you look at the URL in the address bar, you'll see your Client ID. On the previous page, the **Sign In with GitHub** button was in fact a link to an OAuth Authorization page, with your Client ID as a parameter. Sinatra built this link for us when we passed the `CLIENT_ID` into the index.erb template on line 24 of `server.rb`. Sinatra then interpolated our Client ID into the OAuth API link on line 15 of `index.erb`.

Go ahead and Authorize the Application access to your GitHub account data, and you should be redirected to your callback page: `/profile`.

![success](https://user-images.githubusercontent.com/3988879/40751094-f98ceea2-6426-11e8-915a-c44e0f38cfb6.png)

After a successful Application authorization, GitHub provides us with a temporary *authorization grant code* (see it in the URL up there?). We need to `POST` this code to the's `/login/oauth/access_token` endpoint to recieve an *access_token* The access token is what grants us access to the account data that we want to display.

To simplify the process of `POST`ing the authorization grant code back to GitHub, we'll use the [rest-client](https://github.com/rest-client/rest-client) Ruby gem.

First, let's update our `/profile` view to retrieve the temporary authorization grant code. We'll use Sinatra's built in webserver interface, [Rack](https://rack.github.io/) to grab the code from the session data.

``` ruby
get '/profile' do
    # Retrieve temporary authorization grant code
    session_code = request.env['rack.request.query_hash']['code']
    
    erb :profile
end
```

Now that we have the authorization grant code, let's use `rest-client` to `POST` it back to GitHub along with our `CLIENT_ID` and `CLIENT_SECRET` in exchange for our `access_token`.

[DEGW: Why doesn't octokit support this? That seems a little sad. Although I suppose the reason is because it's redundant if you're using something like `omniauth`.]

The `https://github.com/login/oauth/access_token` endpoint expects the following parameters:
Name | Type | Description
-- | -- | --
`client_id` | `string` | __Required.__ Your GitHub OAuth Application Client ID
`client_secret` | `string` | __Required.__ Your GitHub OAuth Application Client Secret
`code` | `string` | __Required.__ The authorization grant code returned after Application authorization

[DEGW: I like this table format. Can we reuse this in other parts of this article too? Other quickstarts?]

Let's also use the request header `:accept` to let the API know that we'd like a `JSON` formatted response.

``` ruby
get '/profile' do
    # Retrieve temporary authorization grant code
    session_code = request.env['rack.request.query_hash']['code']
    
    # POST Auth Grant Code + CLIENT_ID/SECRECT in exchange for our access_token
    response = RestClient.post('https://github.com/login/oauth/access_token',
                    # POST payload
                    {:client_id => CLIENT_ID
                    :client_secret => CLIENT_SECRET
                    :code => session_code},
                    # Request header for JSON response
                    :accept => :json)
    
    erb :profile
end
```

The API's response to our `POST` request will include the access token in a field called `access_token` in the `response` variable. Now we just need to parse out the access token.

``` ruby
get '/profile' do

    ...
    [DEGW: I am adding ellipses here to highlight that the lines below are the ones we are interested in, but I don't know if this is just as confusing…]
    

    #Parse access_token from JSON response
    access_token = JSON.parse(response)['access_token']
        
    erb :profile
end
```

## 4) Use Octokit to Access User Data

Now that we finally have our access token, we can start acessing user data via the GitHub API. Instead of manually calling / handling our own REST request / responses to the API, we can save some time and effort by using GitHub's official Ruby library, [OctoKit](http://octokit.github.io/octokit.rb/).

First, we need initialize the Octokit client by passing it our access token `Octokit::Client.new(:access_token => access_token)`. After that, the user data associated with our `access_token` is available as `client.user`. We can now access any of the [user data properties](https://developer.github.com/v3/users/#get-the-authenticated-user) available from the v3 REST API.

Here is the entire function, with the call to Octokit:

``` ruby
get '/profile' do
    # Retrieve temporary authorization grant code
    session_code = request.env['rack.request.query_hash']['code']
    
    # POST Auth Grant Code + CLIENT_ID/SECRECT in exchange for our access_token
    response = RestClient.post('https://github.com/login/oauth/access_token',
                    # POST payload
                    {:client_id => CLIENT_ID,
                    :client_secret => CLIENT_SECRET,
                    :code => session_code},
                    # Request header for JSON response
                    :accept => :json)
    
    # Parse access_token from JSON response
    access_token = JSON.parse(response)['access_token']
    
    # Initialize Octokit client with user access_token
    client = Octokit::Client.new(:access_token => access_token)
    
    # Create user object for less typing
    user = client.user
    
    # Access user data
    profile_data = {:user_photo_url => user.avatar_url,
                    :user_login => user.login,
                    :user_name => user.name,
                    :user_id => user.id }       
    
    # Render profile page, passing in user profile data to be displayed
    erb :profile, :locals => profile_data
end
```

All of the template [locals](http://sinatrarb.com/intro.html) we'd like to use are packaged up in `profile_data` and will be availble on the `profile.erb` page.

Now we just need to add in the erb partials in `profile.erb` to display the data.

``` html
<body>
    <div class="p-5">
        <div class="blankslate blankslate-narrow p-9">
            <img src="<%= user_photo_url %>" />
            <h3>
                Hey, <a href="<%= user_url %>">@<%= user_login %></a>!
            </h3>
            <p>
                You are GitHub user #<%= user_id %>
            </p>
            <p class="text-gray alt-text-small">
                Click <a href="https://api.github.com/users/<%= user_login %>">here</a> to see all of
                <br>your public profile data
            </p>
        </div>
    </div>
</body>
```

The final result should look something like this:
<img width="969" alt="complete" src="https://user-images.githubusercontent.com/3988879/41005787-bc465d10-68d3-11e8-8b96-eac7b78de8dc.png">

## 5) Digging Deeper

### Scopes
So far, we've only been accessing public data. If you'd like to access private data for things like private emails, repositories or organization information, You'll need to request specific access to those items using [Scopes](https://developer.github.com/apps/building-oauth-apps/understanding-scopes-for-oauth-apps/). It's also possible to reqeust additional permissions from a user at a later point in time. After adding additional permissions to your OAuth Application, your users will be prompted to approve the permission upgrade before you can access any additional user data from that user.

### Persisting Access Tokens
Currently, users are required to **Sign In with GitHub** every time they visit your OAuth Application. It's possible to persist their access token to maintain their session as long as they're signed into GitHub. To do that, you'll need to save their access token to a database [DEGW: How should we handle this? This is a topic too big for this quickstart. Can we point them somewhere? We don't want to leave them hanging!!]
