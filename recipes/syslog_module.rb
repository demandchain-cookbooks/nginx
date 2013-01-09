#
# Cookbook Name:: nginx
# Recipe:: syslog_module
#
# Author:: Artiom Lunev (<artiom.lunev@gmail.com>)
#
# Copyright 2012, Artiom Lunev
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

nginx_src_filepath  = "#{Chef::Config['file_cache_path'] || '/tmp'}/nginx-#{node['nginx']['version']}.tar.gz"

syslog_src_filename = "syslog-"+::File.basename(node['nginx']['syslog']['url'])
syslog_src_filepath = "#{Chef::Config['file_cache_path']}/#{syslog_src_filename}"
syslog_extract_path = "#{Chef::Config['file_cache_path']}/nginx_syslog"

remote_file syslog_src_filepath do
  source node['nginx']['syslog']['url']
  checksum node['nginx']['syslog']['checksum']
  owner "root"
  group "root"
  mode 00644
end

bash "syslog_module" do
  cwd ::File.dirname(syslog_src_filepath)
  code <<-EOH
    mkdir -p #{syslog_extract_path}
    tar xzf #{syslog_src_filename} -C #{syslog_extract_path}
    mv -f #{syslog_extract_path}/*/* #{syslog_extract_path}/
    cd #{::File.dirname(nginx_src_filepath)}/nginx-#{node['nginx']['version']}
  EOH

  not_if { ::File.exists?(syslog_extract_path) }
end

execute "patch nginx" do
  cwd "#{::File.dirname(nginx_src_filepath)}/nginx-#{node['nginx']['version']}"
  returns [ 0 ]
  command "patch -p1 < #{syslog_extract_path}/syslog_#{node['nginx']['version']}.patch"
end

node.run_state['nginx_configure_flags'] =
  node.run_state['nginx_configure_flags'] | ["--add-module=#{syslog_extract_path}"]
