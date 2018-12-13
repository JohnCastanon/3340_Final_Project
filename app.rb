
require "sinatra"
require 'data_mapper'
require 'stripe'
require 'sinatra/flash'

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

# class for the iteams added 
class Items
  include DataMapper::Resource

  property :id, Serial
  property :item, Text
  property :lower, Text
  property :description, Text
  property :seller, Text
  property :condition, Text
  property :imgData, Text
  property :price,Text
  property :zipcode,Text

  #fill in the rest
end

DataMapper.finalize
User.auto_upgrade!
Items.auto_upgrade!



#make an admin user if one doesn't exist!
if User.all(administrator: true).count == 0
  u = User.new
  u.email = "admin@admin.com"
  u.username ="admin"
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

get "/" do
  @Item = Items.all
  erb :index
end

get "/reviews" do

  erb :reviews
end

# takes the sellers information and displays it in the ad.erb

get "/ad/:id" do

    ma = params[:id]
    thing = Items.get(ma)
    @hi = thing
    erb :ad

end

#shows a mockup of reviews when the user click on reviews in the ad.erb

get "/showreviews" do

  erb :showreviews
end

#admin page for the adming
get "/admin" do

  authenticate!
  admin

  erb :admin
end



#gets all the items in the database and displays it in the items.erb
get "/items" do
  authenticate!

  @Item = Items.all


    erb :items

end

#calls the :selling form to a new item 

get "/selling" do
  erb :selling
end 

#checks if the user has more than 25 items which is the limit.
#the params take a description, condition,zipcode, name. 
#the lower property turns the item name in lowercase, which is used in the search bars 
post "/seller/create" do
    authenticate!
    if current_user.objects==25
      flash[:error] ="Your capacity has exceeded!"
      redirect "/items"
    else
  
  
     if params["description"]!="" && params["price"]!="" && params[:file]!=nil
      current_user.update(:objects => current_user.objects+1)
      product = Items.new
      product.item = params["Item"]
      product.lower = params["Item"].downcase
      product.description = params["description"]
      product.condition = params["option"]
      product.price = params["price"]
      product.zipcode = params["zip"]
      product.seller = current_user.email
      product.save

      @filename = params[:file][:filename]
      file = params[:file][:tempfile]
      File.open("./public/images/items/"+(product.id).to_s+"#{@filename}", 'wb') do |f|
      f.write(file.read)
      end
  
      product.imgData="/images/items/"+(product.id).to_s+"#{@filename}"
      product.save 
        flash[:success]="Your object has been added"
        redirect "/items"


     else
      flash[:error]="Item can not be added.Please make sure item's information is set." 
      redirect "/selling" 
    end
  end

end

#show a profile page for the user

get "/profile" do
  erb :profile

end 


#takes you to the pay.erb to Upgrade to a pro user
get "/upgrade" do
    authenticate!
    reg_user 

    erb :pay

end

#used in the items search bars to look up items 
get "/search" do 
    value=params["search"].downcase
    @Item=Items.all(:lower => value)
    erb :items
end 


#used in the homepage search bars, check if there is valid input of zipcode an searchVale 
get "/query" do 
    if params["searchValue"]!="" && params["zipcode"]==""
      value=params["searchValue"].downcase
       @Item=Items.all(:lower => value)

    elsif(params["searchValue"]=="") && (params["zipcode"]!="")
       zip=params["zipcode"]
       @Item=Items.all(:zipcode => zip)

    elsif (params["searchValue"]!="") && (params["zipcode"]!="")
      @Item=Items.all(:lower =>params["searchValue"].downcase)  | Items.all(:zipcode => params["zipcode"])
     
    
    elsif(params["searchValue"]=="") && (params["zipcode"]=="")
      redirect "/"
    end
   
    erb :items
end 

#basic charge for for stripe
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








