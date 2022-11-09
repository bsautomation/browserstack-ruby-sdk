Gem::Specification.new do |s|
  s.name        = "browserstack-ruby-sdk"
  s.version     = "0.1"
  s.summary     = "Ruby Gem to run observability on Browserstack"
  s.description = "Ruby Gem to run observability on Browserstack"
  s.authors     = ['Author']
  s.files       = ["lib/sdk.rb", "lib/sdk_regression.rb", "lib/runner.rb", "lib/data_helper.rb", "lib/rest_helper.rb", "mygem.gemspec"]
  s.bindir      = "exe"
  s.executables << "main"
  s.require_paths = ["lib".freeze]
end