#!/usr/bin/env ruby

require 'yaml'

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
    "--environment #{environment}"
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

  packages = YAML.load(`#{cmd.join(' ')}`)
  packages.collect { |package| package['Filename'] }
end

from_version = find_version(CONFIG['from_lifecycle_environment'])
to_version = find_version(CONFIG['lifecycle_environment'])

from_packages = find_packages(from_version)
to_packages = find_packages(to_version)

report = {
  'new_packages' => (from_packages - to_packages),
  'removed_packages' => (to_packages - from_packages)
}

File.open('package_report.yaml', 'w') do |file|
  file.write(report.to_yaml(:Indent => 4))
end
