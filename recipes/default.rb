#
# Cookbook Name:: ipaclient
# Recipe:: default
#
# Copyright 2014, Infochimps, a CSC Big Data Business
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

Chef::Log.info("node fqdn: #{node[:fqdn]}")
Chef::Log.info("domain: #{node['ipaclient']['domain']}")
Chef::Log.info("Temp path: #{Chef::Config[:file_cache_path]}")

node.default['openssh']['server']['use_p_a_m'] = 'yes'
node.default['openssh']['client']['gssapi_delegate_credentials'] = 'yes'
node.default['openssh']['client']['gssapi_authentication'] = 'yes'
include_recipe 'openssh'

template "/etc/nsswitch.conf" do
  source "nsswitch.conf.erb"
  owner "root"
  group "root"
  mode 0644
end

template "/etc/sudo-ldap.conf" do
  source "sudo-ldap.conf.erb"
  owner "root"
  group "root"
  mode 0644
  SECRETPATH = node['ipaclient']['secretpath']
  pwd_secret = Chef::EncryptedDataBagItem.load_secret("#{SECRETPATH}")
  bindpwd = Chef::EncryptedDataBagItem.load("passwords", "ipapasswords", nss_password)
  base = "#{node['ipaclient']['ldapbase']}"
  variables ({
    ldapbase: "#{base}",
    bindpw: "#{bindpwd}"
             })
end
  
template "/etc/hosts" do
  source "hosts.erb"
  owner "root"
  group "root"
  mode 0644
  host = "#{node['ipaclient']['masterhostname']}"
  ip = "#{node['ipaclient']['domain']}"
  domain = "#{node['ipaclient']['domain']}"
  variables ({
    masterhostname: "#{host}",
    masterip: "#{ip}",
    domain: "#{domain}"
             })
end

template "/usr/sbin/ipa-client-install" do
  source "ipa-client-install.erb"
  mode 0644
  owner  "root"
  group "root"
end

passwordpath = "#{node['ipaclient']['nsspasswordfile']}"
template "#{passwordpath}" do
  pwd_secret = Chef::EncryptedDataBagItem.load_secret("#{SECRETPATH}")
  nss_password = Chef::EncryptedDataBagItem.load("passwords", "ipapasswords", nss_password)
  source "password.erb"
  owner "root"
  group "root"
  mode 0600
  variables ({
    password: "#{nss_password}"
})
end

execute "certutil" do
  # Set up the password file here
  nsspasswordfile = node['ipaclient']['nsspasswordfile']
  command "certutil -N -d /etc/pki/nssdb/ -f #{nsspasswordfile}"
end

execute "client-install" do
  # Set up the encrypted data bag
  SECRETPATH = node['ipaclient']['secretpath']
  pwd_secret = Chef::EncryptedDataBagItem.load_secret("#{SECRETPATH}")
  ipa_password = Chef::EncryptedDataBagItem.load("passwords", "ipapasswords", admin_secret)
  hostname = node[:fqdn].split('.')[0]
  command "ipa-client-install --server=#{hostname}.#{node['ipaclient']['domain']} --domain=#{node['ipaclient']['domain']} --realm=#{node['ipaclient']['realm']} --noac --enable-dns-updates --no-ntp --hostname=#{hostname}.#{node['ipaclient']['domain']} --mkhomedir --password=#{ipa_password} --principal=admin"
end
