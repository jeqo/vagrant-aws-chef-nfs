include_recipe "nfs::client4"

directory "#{node['nfs-client']['local-directory']}" do
  action :create
end

command_mount = "mount -t nfs -o nfsvers=4 #{node['nfs-client']['server-host']}:#{node['nfs-client']['remote-directory']} #{node['nfs-client']['local-directory']}"

execute command_mount do
  action :run
end
