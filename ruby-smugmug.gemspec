$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "smugmug/version.rb"

Gem::Specification.new do |s|
  s.name        = "ruby-smugmug"
  s.version     = SmugMug::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Zachary Anker"]
  s.email       = ["zach.anker@gmail.com"]
  s.homepage    = "http://github.com/zanker/ruby-smugmug"
  s.summary     = "SmugMug 1.3.0 API gem"
  s.description = "Gem for reading and writing data from the SmugMug 1.3.0 API."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "ruby-smugmug"

  s.add_development_dependency "rspec", "~>2.8.0"

  s.files        = Dir.glob("lib/**/*") + %w[LICENSE README.md CHANGELOG.md Rakefile]
  s.require_path = "lib"
end