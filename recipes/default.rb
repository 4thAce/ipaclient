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
  variables (
    ldapbase: "dc=chimpy,dc=internal",
    bindpw: "vowelbear"
  )
end
  
template "/etc/hosts" do
  source "hosts.erb"
  owner "root"
  group "root"
  mode 0644
  variables (
    masterhostname: "ipamasterdev4"
    masterip: "50.17.200.2"
    domain: "chimpy.internal"
  )
end

template "/usr/sbin/ipa-client-install" do
  source "ipa-client-install.erb"
  mode 0644
  owner  "root"
  group "root"
end

package "libnss3-tools"
package "freeipa-client"
package "sssd"
package "openssh-server"

execute "certutil" do
  # Set up the password file here
  command "certutil -N -d /etc/pki/nssdb/ -f #{nsspasswordfile}"
end

execute "client-install" do
  pwd_secret = Chef::EncryptedDataBagItem.load_secret("#{SECRETPATH}")
  ipa_password = Chef::EncryptedDataBagItem.load("passwords", "ipapassword", pwd_secret)
  command "ipa-client-install --server=#{node[:fqdn]}.#{domain} --domain=#{domain} --realm=#{REALM} --noac --enable-dns-updates --no-ntp --hostname=#{node[:fqdn]} --mkhomedir --password=#{ipa_password} --principal=admin"
end
