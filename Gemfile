source "https://rubygems.org"

gem 'profitbricks', '~> 1.0.1'
gem 'chef', '> 10.0.0'

group :test, :development do
  gem 'rake'
  gem 'rspec'
  gem 'guard'
  gem 'guard-rspec'
  gem 'simplecov', require: false
  gem 'coveralls', require: false
  platforms :mri do
    # Temporary fix till hoe works with rbx in 1.9 mode
    gem 'hoe'
    gem 'hoe-git'
    gem 'hoe-gemspec'
    gem 'hoe-bundler'
  end
end