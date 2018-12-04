require "sinatra"
require 'data_mapper'
require 'stripe'

require_relative "authentication.rb"


set :publishable_key, 'pk_test_LnHwpxM8WB49CysYYjAYxFnT'
set :secret_key, 'sk_test_lpv6IRAJZ26PTaXG5hbCwg2S'

Stripe.api_key = settings.secret_key

# need install dm-sqlite-adapter
# if on heroku, use Postgres database
# if not use sqlite3 database I gave you
if ENV['DATABASE_URL']
  DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
else
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/app.db")
end

class Items
  include DataMapper::Resource

  property :id, Serial
  property :item, Text
  property :description, Text
  property :seller, Text
  property :video_url, Text

  #fill in the rest
end

DataMapper.finalize
User.auto_upgrade!
Items.auto_upgrade!


def youtube_embed(youtube_url)
  if youtube_url[/youtu\.be\/([^\?]*)/]
    youtube_id = $1
  else
    # Regex from # http://stackoverflow.com/questions/3452546/javascript-regex-how-to-get-youtube-video-id-from-url/4811367#4811367
    youtube_url[/^.*((v\/)|(embed\/)|(watch\?))\??v?=?([^\&\?]*).*/]
    youtube_id = $5
  end
  %Q{<iframe title="YouTube video player" width="640" height="390" src="https://www.youtube.com/embed/#{ youtube_id }" frameborder="0" allowfullscreen></iframe>}
end




#make an admin user if one doesn't exist!
if User.all(administrator: true).count == 0
  u = User.new
  u.email = "admin@admin.com"
  u.password = "admin"
  u.administrator = true
  u.save

end

def reg_user 
if !current_user || current_user.pro || current_user.administrator
  redirect "/"
end

end 



def pro_user 
if current_user.pro
    redirect "/"
end

end 




def admin
  if !current_user || !current_user.administrator
    redirect "/"
  end
end





#make an admin user if one doesn't exist!
if User.all(administrator: true).count == 0
  u = User.new
  u.email = "admin@admin.com"
  u.password = "admin"
  u.administrator = true
  u.save
end





#the following urls are included in authentication.rb
# GET /login
# GET /logout
# GET /sign_up

# authenticate! will make sure that the user is signed in, if they are not they will be redirected to the login page
# if the user is signed in, current_user will refer to the signed in user object.
# if they are not signed in, current_user will be nil

get "/" do

  erb :index
end

get "/reviews" do

  erb :reviews
end

get "/ad" do

  erb :ad
end

get "/showreviews" do

  erb :showreviews
end

get "/admin" do

  authenticate!
  admin

  erb :admin
end


get "/videos" do
  authenticate!

  @Item = Items.all

  
    erb :items

end

post "/seller/create" do
    authenticate!
     if params["Item"] 
      vid = Items.new
      vid.item = params["Item"]
      vid.description = params["description"]
      vid.seller = current_user.email

      

        vid.save
        return "Item #{vid["title"]} has been added to the marketplace."

     else
     return "Item can not be added.Please make sure item's infomration is set."   
      end

end



get "/upgrade" do
    authenticate!
    reg_user 

    erb :pay

end


get "/selling" do
  erb :selling
end 

post "/charge" do
    # Amount in cents
  @amount = 500

  customer = Stripe::Customer.create(
    :email => current_user.email,
    :source  => params[:stripeToken]
  )

  charge = Stripe::Charge.create(
    :amount      => @amount,
    :description => 'Sinatra Charge',
    :currency    => 'usd',
    :customer    => customer.id
  )

  current_user.pro = true;
  current_user.save
    erb :charge

end









