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

node.default['openssh']['server']['use_p_a_m'] = 'yes'
node.default['openssh']['client']['gssapi_delegate_credentials'] = 'yes'
node.default['openssh']['client']['gssapi_authentication'] = 'yes'
include_recipe 'openssh'
package "libnss3-tools"

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
  bindpwd = Chef::EncryptedDataBagItem.load("passwords", "ipapasswords", pwd_secret)['nss_password']
  variables ({
    :bindpwd => "#{bindpwd}"
  })
end
  
template "/etc/hosts" do
  source "hosts.erb"
  owner "root"
  group "root"
  mode 0644
  hostname = "#{node[:fqdn]}".split('.')[0]
  variables ({
    :hostname => "#{hostname}",
  })
end

template "/usr/sbin/ipa-client-install" do
  source "ipa-client-install.erb"
  mode 0544
  owner  "root"
  group "root"
end

template "#{node['ipaclient']['nsspasswordfile']}" do
  pwd_secret = Chef::EncryptedDataBagItem.load_secret("#{SECRETPATH}")
  nss_password = Chef::EncryptedDataBagItem.load("passwords", "ipapasswords", pwd_secret)['nss_password']
  source "password.erb"
  owner "root"
  group "root"
  mode 0600
  variables ({
    :password => "#{nss_password}"
})
end

remote_directory "/etc/pki/nssdb" do
  owner "root"
  group "root"
  mode 0744
  action :create_if_missing
end

execute "certutil" do
  command "certutil -N -d /etc/pki/nssdb/ -f #{node['ipaclient']['nsspasswordfile']} < /dev/null"
  not_if "test -f /etc/pki/nssdb/cert8.db"
end

#package "python-nss"
#package "python-sss"
apt_repository "sssd" do
  uri "http://ppa.launchpad.net/freeipa/ppa/ubuntu"
  distribution "precise"
  components ["main"]
  key "http://keyserver.ubuntu.com:11371/pks/lookup?op=get&search=0x4F48C3EDC98C220F"
  action :add
end

apt_repository "freeipa" do
  uri "http://ppa.launchpad.net/freeipa/ppa/ubuntu"
  distribution "precise"
  components ["main"]
  key "http://keyserver.ubuntu.com:11371/pks/lookup?op=get&search=0x4F48C3EDC98C220F"
  action :add
end

package "sssd" do
  options "--force-yes"
  action :install
end

package "freeipa" do
  action :install
end

package "openssh" do
  action :install
end

#execute "client-uninstall" do
#end

execute "client-install" do
  # Set up the encrypted data bag
  SECRETPATH = node['ipaclient']['secretpath']
  pwd_secret = Chef::EncryptedDataBagItem.load_secret("#{SECRETPATH}")
  ipa_password = Chef::EncryptedDataBagItem.load("passwords", "ipapasswords", pwd_secret)['admin_secret']
  hostname = "#{node[:fqdn]}".split('.')[0]
  command "ipa-client-install --server=#{hostname}.#{node['ipaclient']['domain']} --domain=#{node['ipaclient']['domain']} --realm=#{node['ipaclient']['realm']} --noac --enable-dns-updates --no-ntp --hostname=#{hostname}.#{node['ipaclient']['domain']} --mkhomedir --password=#{ipa_password} --principal=admin"
end
