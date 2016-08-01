Smackdown
=========

Smackdown lets you compare changes introduced by a particular git repo's branch, and compares that against a
simplecov-format test coverage report in order to report on changed or added lines that are not covered by any tests.

The main intended use case for this is as a test coverage "linter" for pull requests, to make sure that new or changed
code is supported by tests.


Basic Usage
===========

Say we're working on a feature branch called `my_feature`, that we originally branched off of `master`.  In order
to check that all our new and changed code is covered by tests, do the following:

- If you don't already have simplecov set up, check out the README to get started: https://github.com/colszowka/simplecov.

- Install the `simplecov-json` gem and configure simplecov to output JSON as well:

**Gemfile**

```ruby
gem 'simplecov-json', require: false
gem 'smackdown'
```

**Rakefile**
```ruby
require 'smackdown'
```

**test_helper.rb** (or wherever you are running `SimpleCov.start`)

```ruby
require 'simplecov'
require 'simplecov-json'

SimpleCov.start do
  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter
  ]
end
```

- Run your tests to produce the coverage report (`coverage/coverage.json`).

```
bundle exec rake test
```

- Run smackdown.

```
bundle exec rake smackdown

=> All new and modified code is covered!
```

- If your branch _doesn't_ have tests for all new and modified code you've committed (compared to master), you'll instead see a report resembling this:

```
lib/class_with_uncovered_lines.rb
18:     puts "This method was added but no test is written to cover it!"
19:     @some_var = 5

-----------------------------------------
lib/new_class_with_complete_coverage.rb
100% covered!

-----------------------------------------
lib/new_class_with_no_coverage.rb
No coverage for this file!

-----------------------------------------
```

- After you add new tests, remember to re-run your test suite to generate a new coverage report for smackdown to use.


Advanced Usage (Example)
========================

**lib/tasks/my_custom_smackdown_task.rake**

```ruby
desc 'My custom smackdown task'
task :smackdown_custom do
  reporter = Smackdown::CoverageDiffReporter.new(
    "path/to/repo",
    coverage_report_path: "/path/to/repo/coverage/coverage.json",  # This can be a filepath or even a url
    report_path_prefix: "/path/to/repo",  # A string to prefix to files' relative paths in order to make them match the paths
                                          # recorded in the coverage report
    head: "my_feature_for_next_release",
    merge_base: "release_candidate_2016_08_01",
    filters: Smackdown::CoverageDiffReporter.DEFAULT_FILTERS + %w(one_time_scripts/)
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

  exit(reporter.completely_covered?)
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
bundle install
git submodule init
git submodule update --remote
ruby test/script/init.rb  # This will run the tests in the smackdown_test_repo subproject on the my_branch 
                          # and full_smackdown_coverage branches and produce test coverage reports for each
bundle exec rake test
```

Open `coverage/index.html` and verify that you have 100% test coverage!

If you create a branch (i.e. in order to contribute to the gem), you can even use smackdown on the smackdown repo itself in order to verify that your branch's changes are all tested:

```
bundle exec rake smackdown  # dogfooding!
```


How the Tests Work
==================

The test setup here is a little unusual due to the fact that this gem's functionality fundamentally involves comparing 
different revisions in a git repo.

We test this by making use of an ACTUAL git repo which exists solely for the purpose of testing the smackdown gem, and
which is included here as a submodule (hence the submodule init and update steps): https://github.com/robesris/smackdown_test_repo

The `smackdown_test_repo` contains three branches as of this writing: `master`, `my_branch`, and `full_smackdown_coverage`.  The `master` branch includes some sample "app code" that simply defines a few classes with arbitrary methods, as well as a tiny test suite.  The test suite tests one of the methods in the `class_with_uncovered_code_added.rb` file (`covered_method`) but not the other (`existing_uncovered_method`).

Now, `my_branch` represents code changes from master, and adds a new method (really just uncomments the `uncovered_method` method).  However, it does not add any tests to cover this new method.  It also adds a new file with comprehensive tests (`new_class_with_complete_coverage.rb`), and omits tests entirely for another new file (`new_class_with_no_coverage.rb`)

Finally, the `full_smackdown_coverage` branch adds tests for all new and changed code that remains untested in `my_branch`, for the purpose of testing a 100% coverage scenario.

Running `ruby test/script/init.rb` as described above runs the test suite on the `full_smackdown_coverage` and `my_branch` branches, and creates a coverage report for each in the submodule root as `coverage/full_smackdown_coverage.json` and `coverage/coverage.json`, respectively.

What we want to see, in order to verify that `smackdown` is functioning correctly, is as follows:
- The new untested method (`uncovered_method`) is identified by `smackdown` as newly-introduced but uncovered code.
- The untested method that already existed on `master` (`existing_uncovered_method`) is ignored, as it was not introduced by the code changes made in `my_branch`.
- The file with no coverage at all (`new_class_with_no_coverage`) is reported as such.
- The `full_smackdown_coverage` branch is reported as having no changed or added code that is untested.

The tests in the main `smackdown` repo are geared towards testing for these characteristics.


Credit
======

Thanks to @ivantsepp (and his `lintrunner` gem: https://github.com/ivantsepp/lintrunner) for help and inspiration
getting started with this project!
