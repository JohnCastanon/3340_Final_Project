require 'sinatra'
require_relative "user.rb"

enable :sessions

get "/login" do
	erb :"authentication/login"
end



#when login it shows flash messages
post "/process_login" do
	email = params[:email]
	password = params[:password]

	user = User.first(email: email.downcase)

	if(user && user.login(password))
		session[:user_id] = user.id
    flash[:success] = "Welcome #{current_user.username}"
		redirect "/"
	else
    flash[:error]="Could not log in, try again."
    redirect "/login"
	end
end

#takes to the homepage when log out 
get "/logout" do
	session[:user_id] = nil
	redirect "/"
end

get "/sign_up" do
	erb :"authentication/sign_up"
end


post "/register" do
	email = params[:email]
	password = params[:password]
	username= params[:username]

	if (email && password)!="" && User.first(email: email.downcase).nil?
		u = User.new
		u.email = email.downcase
		u.password =  password
		u.username = username
		u.save

		session[:user_id] = u.id

		flash[:success] = "You have signed up"
    redirect "/"
	else
    flash[:error]= "Error, failed to sign up" 
		redirect "/sign_up"
	end

end

#This method will return the user object of the currently signed in user
#Returns nil if not signed in
def current_user
	if(session[:user_id])
		@u ||= User.first(id: session[:user_id])
		return @u
	else
		return nil
	end
end

#if the user is not signed in, will redirect to login page
def authenticate!
	if !current_user
		redirect "/login"
	end
end