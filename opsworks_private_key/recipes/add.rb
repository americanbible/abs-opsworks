Chef::Log.info("adding private repo key for user deploy")

node[:private_key].each do |name, key_contents|
	file "/home/deploy/.ssh/#{name}" do
    content key_contents.gsub(/\\n/, "\n")
    source 'key.erb'
    owner 'deploy'
    group 'deploy'
    mode 0600
  end
end