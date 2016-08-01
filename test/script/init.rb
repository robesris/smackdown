repo_path = File.join(File.dirname(__FILE__), '..', 'smackdown_test_repo')

result = Dir.chdir(repo_path) do
  begin
    system("rm coverage/*") if Dir.exists?("coverage")

    cmds = [
      "git checkout full_smackdown_coverage",
      "bundle install",
      "bundle exec rake test",
      "mv coverage/coverage.json coverage/full_smackdown_coverage.json",
      "mv coverage/index.html coverage/full_smackdown_coverage.html",
      "git checkout my_branch",
      "bundle install",
      "bundle exec rake test"
    ]

    cmds.all? do |cmd|
      puts cmd
      system(cmd)
    end
  ensure
    system("git checkout master")
  end
end

raise "Init failed. Inspect output above to see what went wrong." unless result
