# -*- ruby -*-

require 'rubygems'
require 'hoe'

# vim: syntax=ruby
if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'ruby'
  require 'hoe'
  Hoe.plugin :git
  Hoe.plugin :gemspec
  Hoe.plugin :bundler
  Hoe.plugin :gemcutter
  Hoe.plugins.delete :rubyforge
  Hoe.plugins.delete :spec

  Hoe.spec 'knife-profitbricks' do
    developer('Dominik Sander', 'git@dsander.de')

    self.readme_file = 'README.md'
    self.history_file = 'CHANGELOG.md'
    self.extra_deps << ["profitbricks"]
    self.extra_deps << ["chef", "> 10.0.0"]
  end

  task :prerelease => [:clobber, :check_manifest, :test]
else
  RSpec::Core::RakeTask.new(:spec) do |spec|
    spec.pattern = 'spec/**/*_spec.rb'
    spec.rspec_opts = ['--backtrace']
  end
end

task :default => :spec
task :test => :spec

task :spec do

end