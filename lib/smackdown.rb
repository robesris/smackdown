require 'smackdown/uncovered_line'
require 'smackdown/file_coverage_diff'
require 'smackdown/coverage_diff_reporter'

module Smackdown
  VERSION = File.read(File.join(File.dirname(__FILE__), 'smackdown', 'version.txt')).strip
end
