require 'minitest/autorun'
require 'smackdown'

describe Smackdown do
  before do
    repo_path = File.join(File.dirname(__FILE__), 'smackdown_test_repo')

    @reporter = Smackdown::CoverageDiffReporter.new(
      repo_path,
      head: 'my_branch',
      merge_base: 'master'
    )
    @reporter.run
    @uncovered_file = @reporter.file_coverage_diffs["lib/class_with_uncovered_code_added.rb"]
  end

  describe "uncovered changes" do
    describe "introduced in my_branch" do
      it "reports that the file is not covered" do
        refute @reporter.completely_covered?
        refute @uncovered_file.covered?
      end

      it "reports the uncovered lines" do
        result = @uncovered_file.uncovered_lines.any? do |line|
          line.line_num == 18 && line.line_content == '    puts "This method is added but no test is written to cover it!"'
        end
        assert result
      end
    end

    describe "that were already present" do
      it "does not report the uncovered lines" do
        result = @uncovered_file.uncovered_lines.any? do |line|
          line.line_content == 'puts "Therefore, smackdown should not call it out"'
        end
        refute result
      end
    end
  end
end
