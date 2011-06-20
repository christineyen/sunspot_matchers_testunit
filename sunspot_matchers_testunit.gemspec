# -*- encoding: utf-8 -*-
require File.expand_path("../lib/sunspot_matchers_testunit/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "sunspot_matchers_testunit"
  s.version     = SunspotMatchersTestunit::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Christine Yen"]
  s.email       = []
  s.homepage    = "https://github.com/christineyen/sunspot_matchers_testunit"
  s.summary     = "Test::Unit port of RSpec matchers for testing Sunspot"
  s.description = "These matchers allow you to test what is happening inside the Sunspot Search DSL blocks"
  s.license     = "MIT"

  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "rspec", "~> 2.4.0"
  s.add_development_dependency "sunspot", "~> 1.2.1"
  s.add_development_dependency "rake"

  s.files        = `git ls-files`.split("\n")
  s.require_path = 'lib'
end
