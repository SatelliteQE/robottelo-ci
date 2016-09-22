#!/usr/bin/env ruby

require 'yaml'
require 'json'
require 'openssl'
require 'net/http'


class ContentViewCompare

  attr_reader :config

  def initialize(config)
    @config = config
  end

  def base_command
    [
      'hammer --output yaml',
      "--username #{@config['username']}",
      "--password #{@config['password']}",
      "--server #{@config['server']}"
    ]
  end

  def find_version(environment)
    cmd = [
      "content-view version list",
      "--content-view '#{@config['content_view']}'",
      "--organization '#{@config['organization']}'",
      "--environment '#{environment}'"
    ]
    cmd = base_command.concat(cmd)

    versions = YAML.load(`#{cmd.join(' ')}`)
    versions.first['ID'] unless versions.empty?
  end

  def find_repositories(version_id)
    cmd = [
      'content-view version info',
      "--id #{version_id}"
    ]
    cmd = base_command.concat(cmd)

    repositories = YAML.load(`#{cmd.join(' ')}`)
    repositories['Repositories']
  end

  def find_packages(version_id, repo_id)
    return [] unless version_id
    cmd = [
      "package list",
      "--repository-id '#{repo_id}'"
    ]
    cmd = base_command.concat(cmd)

    YAML.load(`#{cmd.join(' ')}`)
  end

  def compare
    from_version = find_version(@config['from_lifecycle_environment'])
    to_version = find_version(@config['lifecycle_environment'])

    from_repositories = find_repositories(from_version)
    to_repositories = find_repositories(to_version)

    reports = from_repositories.collect do |index, repo|
      from_packages = find_packages(from_version, repo['ID'])
      to_packages = find_packages(to_version, to_repositories[index]['ID']).collect { |package| package['Filename'] }

      new_packages = from_packages.select do |package|
        !to_packages.include?(package['Filename'])
      end

      report = []

      new_packages.each do |package|
        uri = URI("#{@config['server']}/katello/api/v2/packages/#{package['ID']}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Get.new(uri.request_uri)
        request.basic_auth @config['username'], @config['password']

        response = JSON.parse(http.request(request).body)

        report << {"package" => package['Filename'], "sourcerpm" => response['sourcerpm']}
      end

      report = {"#{repo['Name']}" => {'packages' => report}}
    end

    File.open("package_report_#{@config['content_view'].gsub(' ', '_')}.yaml", 'w') do |file|
      file.write(reports.to_yaml(:Indent => 4))
    end
  end
end

config = YAML.load_file('config.yaml')

cv_compare = ContentViewCompare.new(config)
cv_compare.compare
