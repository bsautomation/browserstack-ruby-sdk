Gem::Specification.new do |s|
  s.name        = "mygem"
  s.version     = "0.0.33"
  s.summary     = "Ruby Gem"
  s.description = "A simple gem to test cucumber formatter"
  s.authors     = ['Author']
  s.files       = ["lib/mygem.rb", "lib/runner.rb", "mygem.gemspec"]
  s.bindir      = "exe"
  s.executables = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib".freeze]
end
