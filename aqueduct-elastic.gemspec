# Compiling the Gem
# gem build aqueduct-elastic.gemspec
# gem install ./aqueduct-elastic-x.x.x.gem --no-ri --no-rdoc --local
#
# gem push aqueduct-elastic-x.x.x.gem
# gem list -r aqueduct-elastic
# gem install aqueduct-elastic

$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "aqueduct-elastic/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "aqueduct-elastic"
  s.version     = Aqueduct::Elastic::VERSION::STRING
  s.authors     = ["Remo Mueller"]
  s.email       = ["remosm@gmail.com"]
  s.homepage    = "https://github.com/remomueller"
  s.summary     = "Elastic repository connector for Aqueduct"
  s.description = "Connects and Elastic file server as an aqueduct repository"
  s.license     = 'CC BY-NC-SA 3.0'

  s.files = Dir["{app,config,db,lib}/**/*"] + ["aqueduct-elastic.gemspec", "CHANGELOG.md", "LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails",     "~> 4.0.0"
  s.add_dependency "aqueduct",  "~> 0.2.0"

  s.add_development_dependency "sqlite3"
end
