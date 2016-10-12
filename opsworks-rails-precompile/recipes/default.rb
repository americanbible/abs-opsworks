node[:deploy].each do |application, deploy|
  rails_env = deploy[:rails_env]
  current_path = deploy[:current_path]

  Chef::Log.info("Cleaning Rails assets with environment #{rails_env}")

  execute 'rake assets:clean' do
    cwd current_path
    user 'deploy'
    command 'bundle exec rake assets:clean'
    environment 'RAILS_ENV' => rails_env
  end

  Chef::Log.info("Precompiling Rails assets with environment #{rails_env}")

  execute 'rake assets:precompile' do
    cwd current_path
    user 'deploy'
    command 'bundle exec rake assets:precompile'
    environment 'RAILS_ENV' => rails_env
  end
end
