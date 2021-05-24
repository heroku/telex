# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :rspec, cmd: "zeus rspec" do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/endpoints/(.+)\.rb$}) { |m| "spec/acceptance/#{m[1]}_spec.rb" }
  watch(%r{^lib/(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  watch("spec/spec_helper.rb") { "spec" }
end
