Smackdown
=========

Smackdown lets you compare changes introduced by a particular git repo's branch, and compares that against a
simplecov-format test coverage report in order to report on changed or added lines that are not covered by any tests.

The main intended use case for this is as a test coverage "linter" for pull requests, to make sure that new or changed
code is supported by tests.


Usage
=====

Say we're working on a feature branch called `my_feature`, that we originally branched off of `master`.  In order
to check that all our new and changed code is covered by tests, do the following:

1) Produce a json-format simplecov report for your repo's `my_feature` branch (see the simplecov docs for how to do this: https://github.com/colszowka/simplecov).  This file will normally appear as `coverage/coverage.json` relative to your repo's
root.

2) Use smackdown to get a report on the code that the `my_feature` branch has added and changed since it branched off `master`:

```
reporter = Smackdown::CoverageDiffReporter.new(
  "path/to/repo",
  coverage_report_path: "/path/to/repo/coverage/coverage.json",  # This can be a filepath or even a url
  report_path_prefix: "/path/to/repo",  # A string to prefix to files' relative paths in order to make then match the paths
                                        # recorded in the coverage report
  head: "my_feature",
  merge_base: "master",
  context_lines: 10000,
  filters: Smackdown::CoverageDiffReporter.DEFAULT_FILTERS
)
reporter.run

if reporter.completely_covered?
  puts "All new and modified code is covered!"
else
  reporter.report do |file_coverage_diff|
  puts file_coverage_diff.relative_path

  if file_coverage_diff.coverage_available?
    if file_coverage_diff.covered?
      puts "100\% covered!"
    else
      file_coverage_diff.uncovered_lines.each do |line|
        puts "#{line.line_num}: #{line.line_content}"
      end
    end
  else
    puts "No coverage for this file!"
  end

  puts "\n-----------------------------------------\n"
end
```

NOTES:
- This is example usage and what you do in the block passed to the CoverageDiffReporter#report method is up to you.
- Many of the options passed to CoverageDiffReporter#new are optional and default to common values.  See `lib/coverage_diff_reporter.rb` for more information.
- Instead of passing the path to the coverage report in the `coverage_report_path` parameter, you can instead pass a json
  string in as `coverage_json: my_json_string`


Setting up and Running Tests
============================

Clone the repo, then:

```
cd smackdown
git submodule init
git submodule update
ruby ./test/script/init.rb  # This will run the tests in the smackdown_test_repo subproject and produce a test coverage report
bundle exec rake test
```

Open `coverage/index.html` and verify that you have 100% test coverage!


How the Tests Work
==================

The test setup here is a little unusual due to the fact that this gem's functionality fundamentally involves comparing 
different revisions in a git repo.

We test this by making use of an ACTUAL git repo which exists solely for the purpose of testing the smackdown gem, and
which is included here as a submodule (hence the submodule init and update steps): https://github.com/robesris/smackdown_test_repo

The `smackdown_test_repo` contains two branches as of this writing: `master` and `my_branch`.  The `master` branch includes
some sample "app code" that simply defines a class with a couple methods, as well as a tiny test suite.  The test suite tests
one of the methods in the `master` branch (`covered_method`) but not the other (`existing_uncovered_method`).

Now, `my_branch` represents code changes from master, and adds a new method (really just uncomments the `uncovered_method`
method).  However, it does not add any tests to cover this new method.

Running `ruby ./test/script/init.rb` as described above runs the test suite on the `my_branch` branch, and generates a
coverage report in the submodule root as `coverage/coverage.json`.

What we want to see, in order to verify that `smackdown` is functioning correctly, is as follows:
- The new untested method (`uncovered_method`) is identified by `smackdown` as newly-introduced but uncovered code.
- The untested method that already existed on `master` (`existing_uncovered_method`) is ignored, as it was not introduced by
  the code changes made in `my_branch`.

The tests in the main `smackdown` repo are geared towards testing for these characteristics.


Credit
======

Thanks to @ivantsepp (and his `lintrunner` gem: https://github.com/ivantsepp/lintrunner) for help and inspiration
getting started with this project!
