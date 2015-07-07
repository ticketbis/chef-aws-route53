name 'aws-route53'
maintainer 'Alberto Tablado'
maintainer_email 'alberto.tablad@ticketbis.com'
license 'GPL v3'
source_url 'https://github.com/ticketbis/chef-aws-route53'
description 'Manage Route53 entries'
long_description IO.read(File.join(
  File.dirname(__FILE__), 'README.md'
  )
)
version '0.1.0'

depends 'aws-base'
