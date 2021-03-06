property :bin_prefix, String, default: '/usr'
property :config_dir,  String, default: '/etc/haproxy'
property :config_file, String, default: lazy { ::File.join(config_dir, 'haproxy.cfg') }
property :haproxy_user, String, default: 'haproxy'
property :haproxy_group, String, default: 'haproxy'
property :service_name, String, default: 'haproxy'

action :create do
  with_run_context :root do
    case node['init_package']
    when 'systemd'
      haproxy_systemd_wrapper = ::File.join(new_resource.bin_prefix, 'sbin', 'haproxy-systemd-wrapper')

      poise_service 'haproxy' do
        provider :systemd
        command "#{haproxy_systemd_wrapper} -f #{new_resource.config_file} -p /run/haproxy.pid $OPTIONS"
        options reload_signal: 'USR2',
                restart_mode: 'always',
                after_target: 'network',
                auto_reload: true,
                conf_file: new_resource.config_file,
                pid_file: '/run/haproxy.pid',
                template: 'haproxy:haproxy.service.erb'
        action :enable
      end
    when 'sysvinit'
      poise_service 'haproxy' do
        provider :sysvinit
        command ::File.join(new_resource.bin_prefix, 'sbin', 'haproxy')
        options template: 'haproxy:haproxy-init.erb',
                hostname: node['hostname'],
                conf_dir: new_resource.config_dir,
                pid_file: '/var/run/haproxy.pid',
                run_dir: '/run/haproxy',
                haproxy_user: new_resource.haproxy_user,
                haproxy_group: new_resource.haproxy_group
        action :enable
      end
    end

    poise_service_user new_resource.haproxy_user do
      home "/home/#{new_resource.haproxy_user}"
      group new_resource.haproxy_group
      action :create
    end

    cookbook_file '/etc/default/haproxy' do
      cookbook 'haproxy'
      source 'haproxy-default'
      owner 'root'
      group 'root'
      mode '0644'
    end
  end
end

action :start do
  with_run_context :root do
    resources(poise_service: 'haproxy').run_action(:start)
  end
end

action :stop do
  with_run_context :root do
    resources(poise_service: 'haproxy').run_action(:stop)
  end
end

action :restart do
  with_run_context :root do
    resources(poise_service: 'haproxy').run_action(:restart)
  end
end

action :reload do
  with_run_context :root do
    resources(poise_service: 'haproxy').run_action(:reload)
  end
end

action :enable do
  with_run_context :root do
    resources(poise_service: 'haproxy').run_action(:enable)
  end
end
