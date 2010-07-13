# cleanup
run 'rm README'
run 'rm public/index.html'
run 'rm public/favicon.ico'
run 'rm public/images/rails.png'
create_file 'README.md', <<-README
# #{app_name.humanize}

README

# rvm
create_file ".rvmrc", <<-RVMRC
rvm_gemset_create_on_use_flag=1
rvm gemset use #{app_name}
RVMRC

# javascripts
get "http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js",  "public/javascripts/jquery.js"
get "http://github.com/rails/jquery-ujs/raw/master/src/rails.js", "public/javascripts/rails.js"

initializer "javascripts.rb", <<-JS
ActionView::Helpers::AssetTagHelper.register_javascript_expansion :defaults => %w{
  jquery
  rails
  application
}
JS

# gems
remove_file "Gemfile"
create_file "Gemfile", <<-GEMFILE
source 'http://rubygems.org'
gem 'rails', :git => 'git://github.com/rails/rails.git'

gem "pg",         "0.9.0"
gem "compass"
gem "haml",       ">= 3.0.13"
gem "devise",     :git => "git://github.com/plataformatec/devise.git"
gem "bcrypt-ruby"
gem "simple_form"
gem "responders"
gem "show_for"

group :development do
  gem "heroku"
  gem "taps"
  gem "hirb"
  gem "wirble"
  gem "awesome_print"
  gem "ruby-debug"

  gem "autotest"
  gem "autotest-fsevent" if RUBY_PLATFORM =~ /darwin/
  gem "ZenTest"
end

group :test, :cucumber do
  gem "machinist",        ">= 2.0.0.beta2"
  gem "faker"
  gem "capybara",         ">= 0.3.8"
  gem "cucumber-rails",   ">= 0.3.2"
  gem "database_cleaner", ">= 0.5.2"
  gem "launchy",          ">= 0.3.5"
  gem "rspec-rails",      ">= 2.0.0.beta.17"
  gem "spork",            ">= 0.8.4"
  gem "database_resetter"
end
GEMFILE

application <<-GENERATORS

    config.generators do |g|
      g.template_engine :haml
      g.test_framework :rspec, :fixture => true, :views => false
      g.fixture_replacement :machinist
    end

    config.autoload_paths  += ["\#{config.root}/lib"]
GENERATORS

# haml generator
empty_directory "lib/generators"
git :clone => "git://github.com/psynix/rails3_haml_scaffold_generator.git lib/generators/haml"

remove_dir "lib/generators/.git"

# views
remove_file "app/views/layouts/application.html.erb"
create_file "app/views/layouts/application.html.haml", <<-LAYOUT
!!!
%html
  %head
    %title #{app_name.humanize}
    = stylesheet_link_tag 'screen.css', :media => 'screen, projection'
    = stylesheet_link_tag 'print.css', :media => 'print'
    /[if IE]
      = stylesheet_link_tag 'ie.css', :media => 'screen, projection'
    = csrf_meta_tag
  %body
    = render "shared/flashes"
    = yield
    = javascript_include_tag :defaults
LAYOUT

create_file "app/views/shared/_flashes.html.haml", <<-FLASHES
- if flash.any?
  %div#flash
    - flash.each do |key, value|
      %p= value
FLASHES

# git
create_file "log/.gitkeep"
create_file "tmp/.gitkeep"
git :init
git :add => '.'

# output
log <<-DOCS

Run the following commands to complete the setup of #{app_name.humanize}:

cd #{app_name}
gem install bundler --pre
bundle
rails g rspec:install
rails g cucumber:install --rspec --capybara
rails g machinist:install --cucumber --test-framework rspec
rails g simple_form:install
rails g show_for_install
rails g responders:install
rails g devise:install
compass init rails --sass-dir app/stylesheets --css-dir public/stylesheets --syntax sass
DOCS