module Smackdown
  class FileCoverageDiff
    attr_reader :uncovered_lines, :relative_path, :full_path

    def initialize(relative_path, full_path, coverage, patch)
      @relative_path = relative_path
      @full_path = full_path
      @coverage = coverage
      @patch = patch
      @uncovered_lines = []
      @coverage_available = !coverage.nil?

      record_coverage if @coverage_available
    end

    def coverage_available?
      @coverage_available
    end

    def covered?
      coverage_available? && @uncovered_lines.none?
    end

    def to_s
      str = relative_path

      if coverage_available?
        if covered?
          str += "\n100\% covered!"
        else
          uncovered_lines.each do |line|
            str += "\n#{line.line_num}: #{line.line_content}"
          end
        end
      else
        str += "\nNo coverage for this file!"
      end

      str += "\n\n-----------------------------------------\n"

      str
    end

    private

    def record_coverage
      @patch.hunks.each do |hunk|
        added_lines = hunk.lines.select{ |line| line.line_origin == :addition }
        added_lines.each do |line|
          process_line(line)
        end
      end
    end

    def process_line(line)
      line_number = line.new_lineno
      single_line_hits = @coverage[line_number - 1]
      if single_line_hits && single_line_hits < 1
        line_content = line.content.gsub("\n", "")
        @uncovered_lines << UncoveredLine.new(line_number, line_content)
      end
    end

  end
end
