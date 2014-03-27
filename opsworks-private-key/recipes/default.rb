Chef::Log.info("adding private repo key for user deploy")

node[:repoprivatekey].each do |name, key_contents|
  template "/home/deploy/.ssh/#{name}" do
    cookbook 'opsworks-repo-key'
    source 'key.erb'
    owner 'deploy'
    group 'deploy'
    mode 0600
    variables(:key_contents => key_contents.gsub(/\\n/, "\n"))
  end
end