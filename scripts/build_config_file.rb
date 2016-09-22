#!/usr/bin/env ruby

require 'yaml'

config = {
  'organization' => ENV['organization'],
  'username' => ENV['SATELLITE_USERNAME'],
  'password' => ENV['SATELLITE_PASSWORD'],
  'server' => ENV['SATELLITE_SERVER'],
  'content_view' => ENV['content_view_name'],
  'lifecycle_environment' => ENV['lifecycle_environment'],
  'from_lifecycle_environment' => ENV['from_lifecycle_environment']
}

File.open('config.yaml', 'w') do |file|
  file.write(config.to_yaml)
end
