# Rails --api boilerplate

This is a step by step guide to put a Rails 6 API server in place with the following features:

* [x] Rails new myapp --api
* [x] Rspec for testing
* [x] FactoryBot for fixtures
* [x] Basic User + Game models
* [x] fast_jsonapi as JSON API serializer
* [x] Authentication via Auth0 JWT
  * [x] Authenticated rspec tests (with `valid_headers`)
* [x] CORS enabled
* [x] API versioning
* [ ] Throttling and rate limiting

##### Documentation Sources

* https://sourcey.com/articles/building-the-perfect-rails-api (⚠️ rather old on certain aspects)
* fast_jsonapi https://github.com/Netflix/fast_jsonapi/issues/175
* rack-CORS https://github.com/cyu/rack-cors
* Authenticating via Auth0 JWT token:
  * SPA part: https://auth0.com/docs/quickstart/spa/vanillajs/02-calling-an-api
  * Rails part: https://auth0.com/docs/quickstart/backend/rails

### Rails new myapp --api

```bash
rails new myapp --api --database=postgresql
cd myapp
rm -Rf test # No unit test, will do specification tests via rspec (see below)
vim config/database.yml
# Edit the development and test sections like this:
# development:
#   adapter: sqlite3
#   database: db/development.sqlite3
#   pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
#   timeout: 5000
echo "/config/secrets.yml" >> .gitignore
```

###### Update Gemfile
```diff
--- Gemfile
+++ Gemfile
@@ -5,8 +5,6 @@ ruby '2.7.0'

 # Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
 gem 'rails', '~> 6.0.2', '>= 6.0.2.2'
-# Use postgresql as the database for Active Record
-gem 'pg', '>= 0.18', '< 2.0'
 # Use Puma as the app server
 gem 'puma', '~> 4.1'
 # Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
@@ -31,11 +29,17 @@ group :development, :test do
 end

 group :development do
+  gem 'sqlite3', '~> 1.4.2'
   gem 'listen', '>= 3.0.5', '< 3.2'
   # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
   gem 'spring'
   gem 'spring-watcher-listen', '~> 2.0.0'
 end

+group :production do
+  # Use postgresql as the database for Active Record
+  gem 'pg', '>= 0.18', '< 2.0'
+end
+
```
and `bundle install`

Reference commit: `#f9bbea4`

###### Remove spurious routes

```diff
--- config/application.rb
+++ config/application.rb
@@ -5,15 +5,15 @@ require "rails"
 require "active_model/railtie"
 require "active_job/railtie"
 require "active_record/railtie"
-require "active_storage/engine"
+# require "active_storage/engine"
 require "action_controller/railtie"
 require "action_mailer/railtie"
-require "action_mailbox/engine"
-require "action_text/engine"
+# require "action_mailbox/engine"
+# require "action_text/engine"
 require "action_view/railtie"
-require "action_cable/engine"
+# require "action_cable/engine"
 # require "sprockets/railtie"
-require "rails/test_unit/railtie"
+# require "rails/test_unit/railtie"
```

Then comment the configuration in config files:
```bash
sed -i "s/  config.active_storage/#  config.active_storage/g" config/environments/development.rb
sed -i "s/  config.active_storage/#  config.active_storage/g" config/environments/test.rb
sed -i "s/  config.active_storage/#  config.active_storage/g" config/environments/production.rb
```
Reference commit: `#3b9834b`

### Basic User + Game models
```bash
rails generate scaffold User name:string email:string
rails generate scaffold Game user:references name:string archived:boolean

# Set ', null: false' to Game attributes before doing
bundle exec rake db:migrate

# At that point curl requests are already working:
curl http://localhost:3000/users | jq
# outputs: []
```

Reference commit: `#c1e5f3e`

### FactoryBot for fixtures
Fixtures replacement:
https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md
https://www.driftingruby.com/episodes/sample-data-with-factory-bot-and-faker → Faker can generate

### JSON API serializer (fast_jsonapi)
https://github.com/Netflix/fast_jsonapi → Very detailed documentation

This creates some objects to be instanciated that can return (stringified) JSON very fast.
The goal is to document what the object has to contain (which model attributes, etc). It follows https://jsonapi.org/format/#document-resource-object-related-resource-links standard so is very interesting to use. Particularly URLs for nested ressources and alikes (attribute keys are called 'self:' for such links).

```rb
# Gemfile:

# Faster json serializer
gem 'fast_jsonapi', '~> 1.5.0'
```

Example on the User controller (same applies to Game controller):
```diff
   def index
     @users = User.all

-    render json: @users
+    render json: UserSerializer.new(@users)
   end

   # GET /users/1
   def show
-    render json: @user
+    render json: UserSerializer.new(@user)
   end

   # POST /users
@@ -18,7 +18,7 @@ class UsersController < ApplicationController
     @user = User.new(user_params)

     if @user.save
-      render json: @user, status: :created, location: @user
+      render json: UserSerializer.new(@user), status: :created, location: @user
     else
       render json: @user.errors, status: :unprocessable_entity
     end
@@ -27,7 +27,7 @@ class UsersController < ApplicationController
   # PATCH/PUT /users/1
   def update
     if @user.update(user_params)
-      render json: @user
+      render json: UserSerializer.new(@user)
     else
       render json: @user.errors, status: :unprocessable_entity
     end
```

Serializer Example for User model (same applies to Game):
```rb
# app/serializers/user_serializer.rb
class UserSerializer
  include FastJsonapi::ObjectSerializer

  set_type :user
  set_id :id
  attributes :name, :email, :created_at, :updated_at
  link :self do |user, params|
    Rails.application.routes.url_helpers.user_url(user.id)
  end

  has_many :games, lazy_load_data: true, links: {
    self: -> (user) {
      "https://doc.place2be.io/users/relationships/games"
    },
    related: -> (user) {
        Rails.application.routes.url_helpers.user_games_url(user.id)
      }
  }
end
```

Reference commit: `#7f525ed`

##### Anatomy of a Serializer
* New serializers have to be put in `app/serializers`
* Objects are written like this:
  ```ruby
  class UserSerializer
    include FastJsonapi::ObjectSerializer

    set_type :user
    set_id :id
    attributes :name, :email, :created_at, :updated_at
    link :self do |user, params|
      Rails.application.routes.url_helpers.user_url(user.id)
    end

    has_many :games, lazy_load_data: true, links: {
      self: -> (user) {
        "https://doc.place2be.io/users/relationships/games"
      },
      related: -> (user) {
        Rails.application.routes.url_helpers.user_games_url(user.id)
      }
    }
  end
  ```
* Meta and other parameters can be passed as well, easing the pagination and conditional access to ressources (e.g: supplementary links)

Calling a serializer is actually making a new Serializer object and call
the appropriate function on it
```ruby
UserSerializer.new(u, {include: [:games]}).serialized_json
```

The options object (second argument) is very useful and can specify the nested ressources to return as well when needed.

### Enabling CORS
```rb
# Gemfile:

# Uncomment
gem 'rack-cors'
```

A middleware has to be added, but allowing any origins via '*' is too permissive in my opinion, so I prefer to put three different configs, according to environment.
Here is an example for development:

```rb
# config/environments/devlopment.rb
Rails.application.configure do
  # [...]

  # Rack CORS
  config.cors_origins = 'http://localhost:5000' # '*' it too general
  config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins Rails.application.config.cors_origins
      resource '*', headers: :any, methods: [:get, :post, :options]
    end
  end
end
```

Reference commit: `fdb426e`


### Authentication via Auth0 JWT
https://auth0.com/docs/quickstart/spa/vanillajs/02-calling-an-api
https://auth0.com/docs/quickstart/backend/rails

Reference commit: `4357bf1`

### From secrets.yml to Master Key

* `config/master.key` is not versionized
* `config/credentials.yml.enc` is versionized (bcs encrypted)

The latter is a flat file, but nothing prevents from having environment keys like
```yml
development:
  key1: value
test:
  key1: value
```

And accessing them from the code via:
`Rails.application.credentials[Rails.env.to_sym][:key1]`

Editing credentials is done via:
```bash
EDITOR=vim rails credentials:edit
```

See: https://medium.com/cedarcode/rails-5-2-credentials-9b3324851336

Reference commit: `94909a2`

### Rspec for testing

```rb
# Gemfile:
group :development, :test do
  # Use RSpec for specs
  gem 'rspec-rails', '>= 4.0.0'

  # Use Factory Bot for generating random test data
  gem 'factory_bot_rails', '~> 5.1.1'

  # Use Faker to populate Factories with random data
  gem 'faker', '~> 2.11.0'
end
```

```bash
bin/rails generate rspec:install
```

This will create 3 types of specs:
* `spec/models`: tests models validation
* `spec/requests`: tests real world behavior. All tests are automatically generated, the only things to add are *valid_attributes*, *invalid_attributes* and *new_attributes*.
  Look for `skip` statements to see what has to be implemented.
* `spec/routing`: tests if given routes are correctly routed to a given controller + action

Reference commit: `#5383445`

##### Anatomy of a test
Multiple sources are needed to understand how to craft a good test suite:
* Rspec gem: https://github.com/rspec/rspec-rails/tree/4-0-maintenance
* Good practices: http://www.betterspecs.org
* An opionated way of writing tests: https://leanpub.com/everydayrailsrspec/read
* Test docs: https://relishapp.com/rspec
  You have to choose a version on the *left menu* to land on the correct documentation pages (among `rspec-core`, `rspec-expectations`, `rspec-mocks` and `rspec-rails`)
    * https://relishapp.com/rspec/rspec-core/v/3-9/docs
    * https://relishapp.com/rspec/rspec-expectations/v/3-9/docs
    * https://relishapp.com/rspec/rspec-mocks/v/3-9/docs
    * https://relishapp.com/rspec/rspec-rails/v/4-0/docs

```ruby
# A test is defined as an ExampleGroup class instance:
RSpec.describe Array do
  # content...
end

# The first argument to an example group is a class ('Array' in the example above) and an instance of that class is exposed to each example in that example group via the subject method.
# See: https://relishapp.com/rspec/rspec-core/v/3-9/docs/subject/implicitly-defined-subject

# The tests are crafted with the following structure:
RSpec.describe User, type: :model do

  # Defines a group (can be nested)
  # This doesn't make sense when validating models
  # as RSpec.describe 'Model' is a whole group already
  # but this makes sense when testing requests or
  # routing (each route being an inner group).
  describe "User validation" do

    # Contexts starts with "When", "With" or "Without"
    context "with valid arguments" do

      # Actual test and what is expected
      it "does work" do
        # actual test and assertion here
      end
    end
  end
end

```

### API versioning
Create a `v1` folder under `app/controllers/` and put it the controllers (except `application.rb`).

Your routes goes like this:
```rb
# config/routes.rb
Rails.application.routes.draw do
  # Routes that are common for all API versions
  concern :api_base do
    resources :users do
      resources :games
    end
  end

  scope 'api' do
    namespace 'v1' do
      concerns :api_base
    end

    # Future work
#     namespace 'v2' do
#       concerns :api_base
#     end
  end
end
```

In each moved controller, add a `V1::` prefix to each class definition e.g:
```rb
class V1::UsersController < ApplicationController
end
```

Don't forget to adapt the tests appropriately!

Reference commit: `a01f578`

### API Throttling and rate limiting
Not implemented, see: https://github.com/kickstarter/rack-attack gem for reference.
