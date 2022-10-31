Gem::Specification.new do |s|
  s.name        = "mygem"
  s.version     = "0.0.31"
  s.summary     = "Ruby Gem"
  s.description = "A simple gem to test cucumber formatter"
  s.authors     = ['Author']
  s.files       = ["lib/mygem.rb", "lib/runner.rb"]
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
end
