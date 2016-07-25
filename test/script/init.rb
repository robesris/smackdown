repo_path = File.join(File.dirname(__FILE__), '..', 'smackdown_test_repo')

result = Dir.chdir(repo_path) do
  begin
    system("rm coverage/*") if Dir.exists?("coverage")

    cmds = [
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

exit(result)
