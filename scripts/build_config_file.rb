#!/usr/bin/env ruby

require 'yaml'

content_view = ENV['content_view_name']
type = content_view.split(' ')[0]
rhel = content_view.split(' ')[1]

config = {
  'organization' => ENV['organization'],
  'username' => ENV['SATELLITE_USERNAME'],
  'password' => ENV['SATELLITE_PASSWORD'],
  'server' => ENV['SATELLITE_SERVER'],
  'product' => "Red Hat #{type} 6.2 Composes",
  'repository' => "#{rhel} #{type} x86_64 os",
  'content_view' => content_view,
  'lifecycle_environment' => ENV['lifecycle_environment'],
  'from_lifecycle_environment' => ENV['from_lifecycle_environment']
}

File.open('config.yaml', 'w') do |file|
  file.write(config.to_yaml)
end
