package "monit"

node[:deploy].each do |application, deploy|

  service "monit" do
    supports :restart => true, :reload => true
    action :enable
  end

  Chef::Log.info("Writing monit configs for resque jobs")

  node[:monit][:resque][:workers].times do |x|
    template "/etc/monit/conf.d/#{application}.worker_#{x}.monitrc" do
      source 'monit.worker.erb'
      mode '0640'
      owner 'root'
      group 'root'
      variables({
        :idx => x,
        :rails_env => deploy[:rails_env],
        :app_name => application
      })
      notifies :reload, 'service[monit]'
    end
  end

  Chef::Log.info("Writing monit config for resque scheduler")

  template "/etc/monit/conf.d/#{application}.scheduler.monitrc" do
    source 'monit.scheduler.erb'
    mode '0640'
    owner 'root'
    group 'root'
    variables({
      :rails_env => deploy[:rails_env],
      :app_name => application
    })
    notifies :reload, 'service[monit]'
    only_if { node[:monit][:resque][:scheduler] }
  end

  include_recipe "opsworks_monit_resque::restart"
end
