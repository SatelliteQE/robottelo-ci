#!/usr/bin/env ruby

require 'yaml'
require 'json'
require 'openssl'
require 'net/http'

CONFIG = YAML.load_file('config.yaml')

def base_command
  [
    'hammer --output yaml',
    "--username #{CONFIG['username']}",
    "--password #{CONFIG['password']}",
    "--server #{CONFIG['server']}"
  ]
end

def find_version(environment)
  cmd = [
    "content-view version list",
    "--content-view '#{CONFIG['content_view']}'",
    "--organization '#{CONFIG['organization']}'",
    "--environment '#{environment}'"
  ]
  cmd = base_command.concat(cmd)

  versions = YAML.load(`#{cmd.join(' ')}`)
  versions.first['ID'] unless versions.empty?
end

def find_packages(version_id)
  return [] unless version_id
  cmd = [
    "package list",
    "--organization #{CONFIG['organization']}",
    "--repository '#{CONFIG['repository']}'",
    "--product '#{CONFIG['product']}'",
    "--content-view-version-id #{version_id}"
  ]
  cmd = base_command.concat(cmd)

  YAML.load(`#{cmd.join(' ')}`)
end

from_version = find_version(CONFIG['from_lifecycle_environment'])
to_version = find_version(CONFIG['lifecycle_environment'])

from_packages = find_packages(from_version)
to_packages = find_packages(to_version).collect { |package| package['Filename'] }

new_packages = from_packages.select do |package|
  !to_packages.include?(package['Filename'])
end

report = []

new_packages.each do |package|
  uri = URI("#{CONFIG['server']}/katello/api/v2/packages/#{package['ID']}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Get.new(uri.request_uri)
  request.basic_auth CONFIG['username'], CONFIG['password']

  response = JSON.parse(http.request(request).body)

  report << {"package" => package['Filename'], "sourcerpm" => response['sourcerpm']}
end

File.open("package_report_#{CONFIG['content_view'].gsub(' ', '_')}.yaml", 'w') do |file|
  file.write(report.to_yaml(:Indent => 4))
end
