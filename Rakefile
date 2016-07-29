require 'bundler/gem_tasks'
require 'smackdown'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc "Run tests"
task :default => :test
