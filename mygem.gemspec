Gem::Specification.new do |s|
  s.name        = "mygem"
  s.version     = "0.0.34"
  s.summary     = "Ruby Gem"
  s.description = "A simple gem to test cucumber formatter"
  s.authors     = ['Author']
  s.files       = ["lib/mygem.rb", "lib/runner.rb", "mygem.gemspec"]
  s.bindir      = "exe"
  s.executables << "mygem"
  s.require_paths = ["lib".freeze]
end
