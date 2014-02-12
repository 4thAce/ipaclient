name             'ipaclient'
maintainer       'Infochimps, a CSC Big Data Business'
maintainer_email 'richard.magahiz@infochimps.com'
license          'Apache 2.0'
description      'Installs/Configures ipaclient'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.3'
depends          'apt', '~> 1.9.0'
depends          'openssh', '~> 1.3.2'

recipe           "ipaclient::default",              "Base config"
recipe           "ipaclient::install_client",       "Install, set up ipa client"

%w[ debian ubuntu ].each do |os|
  supports os
end

