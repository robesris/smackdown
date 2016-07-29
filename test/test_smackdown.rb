require "minitest/autorun"
require "smackdown"

def check_results
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

  describe "displaying a report" do
    describe "with default behavior" do
      before do
        @report_output = @reporter.report
      end

      it "should report accurate information about the coverage" do
        assert_match('puts "This method is added but no test is written to cover it!"', @report_output)
      end
    end

    describe "with an explicit block provided" do
      before do
        @report_output = ""
        @reporter.report do |file_coverage_diff|
          @report_output += "#{file_coverage_diff.relative_path}: #{file_coverage_diff.uncovered_lines.count} uncovered line(s).\n"
        end
      end

      it "should report accurate information about the coverage" do
        assert_match(/lib\/class_with_uncovered_code_added\.rb\: 1 uncovered line\(s\)\./, @report_output)
      end
    end
  end
end

describe "normal usage" do
  before do
    @repo_path = File.join(File.dirname(__FILE__), "smackdown_test_repo")
  end

  describe "using a test coverage report file path" do
    describe "on the local filesystem" do
      before do
        @reporter = Smackdown::CoverageDiffReporter.new(
          @repo_path,
          head: "my_branch",
          merge_base: "master"
        )
        @reporter.run
        @uncovered_file = @reporter.file_coverage_diffs["lib/class_with_uncovered_code_added.rb"]
      end

      check_results
    end

    describe "at a remote url" do
      before do
        url = "http://mycoveragereports.com/reports/1"

        # Fake the http call
        coverage_report_path = File.join(@repo_path, "coverage", "coverage.json")
        coverage_json = File.read(coverage_report_path)
        Net::HTTP.expects(:get).with(URI(url)).returns(coverage_json)

        @reporter = Smackdown::CoverageDiffReporter.new(
          @repo_path,
          coverage_report_path: url,
          head: "my_branch",
          merge_base: "master"
        )
        @reporter.run
        @uncovered_file = @reporter.file_coverage_diffs["lib/class_with_uncovered_code_added.rb"]
      end

      check_results
    end
  end

  describe "using a json string" do
    before do
      coverage_report_path = File.join(@repo_path, "coverage", "coverage.json")
      coverage_json = File.read(coverage_report_path)

      @reporter = Smackdown::CoverageDiffReporter.new(
        @repo_path,
        head: "my_branch",
        merge_base: "master",
        coverage_json: coverage_json
      )
      @reporter.run
      @uncovered_file = @reporter.file_coverage_diffs["lib/class_with_uncovered_code_added.rb"]
    end

    check_results
  end
end

describe "error conditions" do
  describe "attempting to initialize with both a coverage report path and a json string" do
    before do
      @repo_path = File.join(File.dirname(__FILE__), "smackdown_test_repo")
      coverage_report_path = File.join(@repo_path, "coverage", "coverage.json")
      @coverage_json = JSON.parse(File.read(coverage_report_path))
    end

    it "raises an error" do
      error = assert_raises(RuntimeError) do
        Smackdown::CoverageDiffReporter.new(
          @repo_path,
          head: "my_branch",
          merge_base: "master",
          coverage_report_path: @repo_path,
          coverage_json: @coverage_json
        )
      end

      assert_equal "Please pass only :coverage_report_path or :coverage_json, not both.", error.message
    end
  end
end

describe "ULTIMATE DOGFOODING" do
  describe "running the rake task" do
    it "indicates that our new and changed code is all covered by tests" do
      coverage_file_path = File.join(File.dirname(__FILE__), '../coverage/coverage.json')
      unless File.exist?(coverage_file_path)
        message = %Q{
          Skipping the ULTIMATE DOGFOODING test for the smackdown rake task because the test coverage file
          (coverage/coverage.json) does not exist. This is likely because this is the first time you are running
          this test suite. After this run, however, the coverage file should have been created, and you should see
          this test pass if you run the suite a second time.

          This odd situation is due to the rather meta, recursive-ish nature of this test, which is in a way
          testing the test coverage report itself.
        }
        puts message
        skip("No coverage file available.")
      end
      assert_equal "All new and modified code is covered!", `rake smackdown`
    end
  end
end
