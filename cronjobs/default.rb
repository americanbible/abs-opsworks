node[:custom_env][:cron_jobs].each do |cron_values|
  cron "#{cron_values[:name]}" do
    minute  "#{cron_values[:minute]}"
    hour    "#{cron_values[:hour]}"
    day     "#{cron_values[:day]}"
    month   "#{cron_values[:month]}"
    weekday "#{cron_values[:weekday]}"
    command "#{cron_values[:command]}"
  end
end
