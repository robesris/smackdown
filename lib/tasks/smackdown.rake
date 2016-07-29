desc "Run smackdown on your current branch with the most common options"
task :smackdown do
  reporter = Smackdown::CoverageDiffReporter.new(File.expand_path('.'))
  reporter.run
  puts reporter.report

  exit(reporter.completely_covered?)
end
