require 'json'
require 'rugged'

require 'smackdown/uncovered_line'
require 'smackdown/file_coverage_diff'
require 'smackdown/coverage_diff_reporter'

module Smackdown
  class Tasks
    include Rake::DSL if defined? Rake::DSL

    def install_tasks
      import File.join(File.dirname(__FILE__), 'tasks/smackdown.rake')
    end
  end
end

Smackdown::Tasks.new.install_tasks
