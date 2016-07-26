require 'simplecov'
require 'simplecov-json'

SimpleCov.start do
  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter
  ]
end
