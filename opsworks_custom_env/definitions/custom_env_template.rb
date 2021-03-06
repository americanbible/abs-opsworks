# Accepts:
#   application (application name)
#   deploy (hash of deploy attributes)
#   env (hash of custom environment settings)
#
# Notifies a "restart Rails app <name> for custom env" resource.

define :custom_env_template do

  params[:env].each do |key, value|
    Chef::Log.info("Setting ENV[#{key}] to #{value}")
    # ENV[key] = value
    `export #{key}=#{value}`
  end

  template "/home/deploy/.bashrc" do
    source "deploybashrc.erb"
    owner params[:deploy][:user]
    group params[:deploy][:group]
    mode "0660"
    variables :env => params[:env]
  end

  template "/root/.bashrc" do
    source "rootbashrc.erb"
    owner "root"
    group "root"
    mode "0660"
    variables :env => params[:env]
  end

  template "#{params[:deploy][:deploy_to]}/shared/config/application.yml" do
    source "application.yml.erb"
    owner params[:deploy][:user]
    group params[:deploy][:group]
    mode "0660"
    variables :env => params[:env]
    notifies :run, resources(:execute => "restart Rails app #{params[:application]} for custom env")

    only_if do
      File.exists?("#{params[:deploy][:deploy_to]}/shared/config")
    end
  end
end
