Test Setup
==========

Clone the repo, then:

```
cd smackdown
git submodule init
git submodule update
ruby ./test/script/init.rb  # This will run the tests in the smackdown_test_repo subproject and produce a test coverage report
bundle exec rake test
```
