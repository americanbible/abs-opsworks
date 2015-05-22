node[:deploy].each do |application, deploy|

  Chef::Log.info("Restarting resque jobs via monit")

  execute 'restart resque' do
    user 'root'
    command 'monit -g resque restart all'
  end
end
