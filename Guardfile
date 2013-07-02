# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :rspec, cli: '--backtrace --color' do
  watch(%r{^spec/unit/.+_spec\.rb$})
  watch('spec/spec_helper.rb')  { "spec" }

  watch(%r{^lib/chef/knife/(.+)\.rb$})                           { |m| "spec/unit/#{m[1]}_spec.rb" }
end


