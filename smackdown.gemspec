# -*- encoding: utf-8 -*-
# $LOAD_PATH.unshift "lib"
$:.push File.expand_path("../lib", __FILE__)

require "smackdown"

Gem::Specification.new do |s|
  s.name          = "smackdown"
  s.version       = Smackdown::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["Rob Esris"]
  s.email         = ["resris@paperlesspost.com"]
  s.description   = "Identify and report on lines of code, introduced in a branch (e.g. a pull request) that are not covered by tests."
  s.files         = Dir.glob("{lib}/**/*")
  s.require_path  = "lib"

  s.add_runtime_dependency 'rugged', '0.19.0'
end
