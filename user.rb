require 'data_mapper' # metagem, requires common plugins too.


if ENV['DATABASE_URL']
  DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
else
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/app.db")
end

class 
    User
    include DataMapper::Resource
    property :id, Serial
    property :email, String
    property :username, String
    property :password, String
    property :created_at, DateTime
    property :objects, Integer, :default => 0 
    property :administrator, Boolean, :default => false
    property :pro, Boolean, :default => false


    def login(password)
        return self.password == password
    end
end

# Perform basic sanity checks and initialize all relationships
# Call this when you've defined all your models
DataMapper.finalize

# automatically create the post table
User.auto_upgrade!

