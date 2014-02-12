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

default['ipaclient']['nsspasswordfile'] = "#{Chef::Config[:file_cache_path]}/password"
#default['ipaclient']['secretpath'] = "#{Chef::Config[:file_cache_path]}/adminsecret"
default['ipaclient']['secretpath'] = "/tmp/adminsecret"
default['ipaclient']['realm'] = 'CHIMPY.INTERNAL'
default['ipaclient']['domain'] = 'chimpy.internal'
default['ipaclient']['ldapbase'] = 'dc=chimpy,dc=internal'
default['ipaclient']['masterip'] = '50.17.200.2'
default['ipaclient']['masterhostname'] = 'ipamasterdev4'
