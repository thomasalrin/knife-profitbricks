$:.unshift File.expand_path('../../lib', __FILE__)


if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start
else
  require 'coveralls'
  Coveralls.wear!
end

require 'chef'
require 'profitbricks'
#require 'chef/knife/winrm_base'
require 'chef/knife/profitbricks_base'
require 'chef/knife/profitbricks_images_list'
require 'chef/knife/profitbricks_server_create'
require 'chef/knife/profitbricks_server_list'