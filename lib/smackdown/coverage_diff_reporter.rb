module Smackdown
  class CoverageDiffReporter
    DEFAULT_FILTERS = %w(
      ^[^\/]*$
      test/
      features/
      spec/
      autotest/
      config/
      db/
      vendor/bundle/
      script
      vendor
    )

    attr_reader :file_coverage_diffs

    def initialize(repo_path, opts = {})
      raise "Repo path does not exist: #{repo_path}" unless Dir.exists?(repo_path)
      @repo                 = Rugged::Repository.new(repo_path)

      @coverage_report_path = opts[:coverage_report_path] || File.join(repo_path, 'coverage', 'coverage.json')
      @report_path_prefix   = opts[:report_path_prefix] || repo_path
      @head                 = opts[:head] || 'HEAD'
      @merge_base           = opts[:merge_base] || 'master'
      @context_lines        = opts[:context_lines] || 10000
      @filters              = opts[:filters] || DEFAULT_FILTERS
      @file_coverage_diffs  = {}
    end

    def run
      parse_coverage_report

      @diff = @repo.diff(@repo.merge_base(@merge_base, @head), @head, context_lines: @context_lines)

      process_diffs
    end

    def completely_covered?
      @file_coverage_diffs.all? do |_relative_path, file_coverage_diff|
        file_coverage_diff.covered?
      end
    end

    def report(&block)
      @file_coverage_diffs.each do |_relative_path, file_coverage_diff|
        yield file_coverage_diff
      end
    end

    private

    def parse_coverage_report
      uri = URI(@coverage_report_path)
      if ["http", "https"].include?(uri.scheme)
        file_contents = Net::HTTP.get(uri)
      else
        raise "Coverage report path does not exist: #{@coverage_report_path}" unless File.exists?(@coverage_report_path)
        file_contents = File.read(@coverage_report_path)
      end
      coverage_json = JSON.parse(file_contents)
      @coverage_json_hash = Hash.new
      coverage_json["files"].each do |file_diff|
        @coverage_json_hash[file_diff["filename"]] = file_diff["coverage"]
      end
    end

    def process_diffs
      @diff.patches.each do |patch|
        relative_path = patch.delta.new_file[:path]

        next if @filters.any?{ |filter| /^#{filter}/.match relative_path }

        full_path = File.join(@report_path_prefix, relative_path)
        coverage = @coverage_json_hash[full_path]

        @file_coverage_diffs[relative_path] = FileCoverageDiff.new(relative_path, full_path, coverage, patch)
      end
    end
  end
end
