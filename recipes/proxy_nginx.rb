#
# Cookbook Name:: jenkins
# Recipe:: proxy_nginx
#
# Author:: Fletcher Nichol <fnichol@nichol.ca>
#
# Copyright 2011, Fletcher Nichol
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in wrhiting, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#let me decide how to install nginx, use role to compose
#include_recipe "nginx::source"

if node['jenkins']['http_proxy']['www_redirect'] == "enable"
  www_redirect = true
else
  www_redirect = false
end

host_name = node['jenkins']['http_proxy']['host_name'] || node['fqdn']

if node['jenkins']['http_proxy']['ssl']
  proxy = data_bag_item('jenkins', 'proxy')

  directory File.join(node['nginx']['dir'], 'ssl') do
    owner 'root'
    group 'root'
    mode '0755'
  end

  %w(key cert).each do |item|
    file File.join(node['nginx']['dir'], 'ssl', "jenkins.#{item}") do
      content proxy['ssl'][item]
      mode 0644
    end
  end

end

template "#{node['nginx']['dir']}/sites-available/jenkins.conf" do
  source "nginx_jenkins.conf.erb"
  owner 'root'
  group 'root'
  mode '0644'
  variables(
      :host_name       => host_name,
      :host_aliases    => node['jenkins']['http_proxy']['host_aliases'],
      :listen_ports    => node['jenkins']['http_proxy']['listen_ports'],
      :www_redirect    => www_redirect,
      :max_upload_size => node['jenkins']['http_proxy']['client_max_body_size'],
      :ssl_key         => File.join(node['nginx']['dir'], 'ssl', 'jenkins.key'),
      :ssl_cert        => File.join(node['nginx']['dir'], 'ssl', 'jenkins.cert')
  )

  if File.exists?("#{node['nginx']['dir']}/sites-enabled/jenkins.conf")
    notifies :restart, 'service[nginx]'
  end
end

nginx_site "jenkins.conf" do
  if node['jenkins']['http_proxy']['variant'] == "nginx"
    enable true
  else
    enable false
  end
end
