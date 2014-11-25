include_recipe "nfs::server4"

directory node['nfs-server']['shared-directory'] do
end

nfs_export node['nfs-server']['shared-directory'] do
  network '*'
  writeable true
  sync true
  options ['insecure']
end
