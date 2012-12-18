#
# Cookbook Name:: nginx
# Recipe:: xrid_module
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

xrid_src_filename = "xrid-"+::File.basename(node['nginx']['xrid']['url'])
xrid_src_filepath = "#{Chef::Config['file_cache_path']}/#{xrid_src_filename}"
xrid_extract_path = "#{Chef::Config['file_cache_path']}/nginx_xrid"

%w( libssl-dev zlib1g-dev libcurl4-openssl-dev libpcre3-dev libossp-uuid-dev ).each { |p| package p }

remote_file xrid_src_filepath do
  source node['nginx']['xrid']['url']
  checksum node['nginx']['xrid']['checksum']
  owner "root"
  group "root"
  mode 00644
end

bash "xrid_module" do
  cwd ::File.dirname(xrid_src_filepath)
  code <<-EOH
    mkdir -p #{xrid_extract_path}
    tar xzf #{xrid_src_filename} -C #{xrid_extract_path}
    mv -f #{xrid_extract_path}/*/* #{xrid_extract_path}/
  EOH

  not_if { ::File.exists?(xrid_extract_path) }
end

node.run_state['nginx_configure_flags'] =
  node.run_state['nginx_configure_flags'] | ["--add-module=#{xrid_extract_path}", "--with-cc-opt='-I/usr/include/ossp'", "--with-ld-opt='-lossp-uuid'"]
