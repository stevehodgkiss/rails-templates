run "rm public/images/rails.png"
run "rm public/index.html"
run "rm -f public/javascripts/*"
run "curl -s -L http://jqueryjs.googlecode.com/files/jquery-1.3.1.min.js > public/javascripts/jquery.js"

git :init

append_file '.gitignore', %{
*~
*.swp
.DS_Store
server/
pkg/
bench/
log/*
tmp/*
db/*.sqlite3
config/database.yml
*.sql
_site/
vendor/bundler_gems/*
!vendor/bundler_gems/cache/
bin/
}.strip

# Bundler
# based on http://tomafro.net/2009/11/a-rails-template-for-gem-bundler

# git :submodule => 'add git://github.com/wycats/bundler.git vendor/bundler'
inside 'gems/bundler' do  
  run 'git init'
  run 'git pull --depth 1 git://github.com/wycats/bundler.git' 
  run 'rm -rf .git .gitignore'
end

file 'script/bundle', %{
#!/usr/bin/env ruby
$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "vendor/bundler/lib"))
require 'rubygems'
require 'rubygems/command'
require 'bundler'
require 'bundler/commands/bundle_command'
Gem::Commands::BundleCommand.new.invoke(*ARGV)
}.strip

file 'Gemfile', %{
clear_sources
bundle_path "vendor/bundler_gems"
source "http://gemcutter.org"
source "http://gems.github.com"
# disable_system_gems

gem "rails",          "2.3.5"
gem "rack",           "1.0.1"
gem "will_paginate",  "2.3.11"
gem "formtastic",     "0.9.7"
gem "haml", "2.2.16"
gem "compass", "0.8.17"

only :test do
  gem "cucumber",     "0.3.101"
  gem "factory_girl", "1.2.3"
  gem "webrat",       "0.5.3"
end
}.strip

run 'chmod +x script/bundle'
run 'script/bundle'

git :add => 'vendor/bundler_gems/ruby/1.8/cache/ -f'
 
append_file '/config/preinitializer.rb', %{
require File.expand_path(File.join(File.dirname(__FILE__), "..", "vendor", "bundler_gems", "environment"))
}.strip
 
gsub_file 'config/environment.rb', "require File.join(File.dirname(__FILE__), 'boot')", %{
require File.join(File.dirname(__FILE__), 'boot')
 
# Hijack rails initializer to load the bundler gem environment before loading the rails environment.
 
Rails::Initializer.module_eval do
  alias load_environment_without_bundler load_environment
  
  def load_environment
    Bundler.require_env configuration.environment
    load_environment_without_bundler
  end
end
}.strip

file 'app/controllers/application_controller.rb', %{
class ApplicationController < ActionController::Base
  helper :all
  protect_from_forgery
  filter_parameter_logging :password

  unless ActionController::Base.consider_all_requests_local
    rescue_from ActiveRecord::RecordNotFound,         :with => :render_404
    rescue_from ActionController::UnknownController,  :with => :render_404
    rescue_from ActionController::UnknownAction,      :with => :render_404
  end

  private

  def render_404(exception)
    log_error(exception)
    render :file => "public/404.html", :status => 404
  end
end
}.strip

file 'app/helpers/application_helper.rb', %{
module ApplicationHelper
  def body_class
    "\#{controller.controller_name} \#{controller.controller_name}-\#{controller.action_name}"
  end
end
}.strip

# haml views

file 'app/views/layouts/application.html.haml', %{
!!!
%html
  %head
    %meta{:charset => 'UTF-8'}
    %title Application
    = stylesheet_link_tag 'compiled/screen.css', :media => 'screen, projection'
  %body{:class => body_class}
    %div#container
      = render :partial => 'shared/flashes'
      = yield
      = render :partial => 'shared/javascript'
}.strip

file 'app/views/shared/_flashes.html.haml', %{
%div#flash
  - flash.each do |key, value|
    %div{:class => key}= value
}.strip

file 'app/views/shared/_javascript.html.haml', %{
= javascript_include_tag 'application'
= yield :javascript
}.strip

file 'app/stylesheets/screen.sass', %{}

file 'config/compass.rb', %{
project_type = :rails
project_path = RAILS_ROOT if defined?(RAILS_ROOT)
http_path = "/"
css_dir = "public/stylesheets/compiled"
sass_dir = "app/stylesheets"
}.strip

file 'config/initializers/compass.rb', %{
require 'compass'
Compass.configuration.parse(File.join(RAILS_ROOT, "config", "compass.rb"))
Compass.configuration.environment = RAILS_ENV.to_sym
Compass.configure_sass_plugin!
}.strip

initializer 'haml.rb', %{
require 'haml'
Haml.init_rails(nil)
Haml::Template.options[:format] = :html5
}.strip

git :add => '.'

git :commit => '-m "initial commit"'