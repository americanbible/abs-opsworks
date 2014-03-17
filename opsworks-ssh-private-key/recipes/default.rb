group 'opsworks'

Chef::Log.info("setting private key for user deploy")

node[:sshprivatersakey].each do |private_rsa_key|
  template "/home/deploy/.ssh/id_rsa" do
    cookbook 'opsworks-ssh-private-key'
    source 'id_rsa.erb'
    owner deploy
    group 'deploy'
    variables(:private_key => private_rsa_key.gsub(/\\n/, "\n"))
  end
end

