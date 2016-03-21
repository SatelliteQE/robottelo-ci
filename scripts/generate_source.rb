#!/usr/bin/env ruby

class SourceBuilder

  attr_accessor :repository, :ref, :exit_code

  def initialize
    self.exit_code = 0
  end

  def build(repository, ref)
    self.repository = repository
    self.ref = ref

    if File.exists?('Rakefile') && system('rake -T | grep pkg:generate_source')
      puts "Found pkg:generate_source rake task; running rake pkg:generate_source"
      sys_call('rake pkg:generate_source')
      artifact = "pkg/*"
    elsif gemspec?
      puts "Found gemspec; building gem"
      sys_call("gem build *.gemspec")
      artifact = "*.gem"
    else
      puts "Building git archive tarball"
      artifact = "#{repository}-#{ref}.tar.bz2"
      sys_call("git archive --prefix=#{@repository}-#{@ref}/ #{@ref} | bzip2 -9 > #{artifact}")
    end

    scp_artifact(artifact)
    cleanup
  end

  def upload(location)
    `wget #{location} --no-check-certificate`
    filename = File.basename(location)
    scp_artifact(filename)
    cleanup(filename)
  end

  private

  def scp_artifact(artifact)
    sys_call("scp #{artifact} jenkins@#{ENV['SOURCE_FILE_HOST']}:/var/www/html/pub/sources/6.2")
  end

  def clone
    sys_call("git -c http.sslVerify=false clone https://#{ENV['GIT_HOSTNAME']}/#{ENV['GIT_ORGANIZATION']}/#{@repository}.git")
  end

  def gemspec?
    !Dir.glob('*.gemspec').empty?
  end

  def cleanup(files = nil)
    if files
      puts "Cleaning up #{files}"
      system("rm -rf #{files}")
    end
    exit @exit_code
  end

  def sys_call(command)
    puts command
    success = system(command)
    @exit_code = 1 if !success
    success
  end
end

builder = SourceBuilder.new

if ENV['source']
  puts "Uploading #{source} to #{ENV['SOURCE_FILE_HOST']}"
  builder.upload(ENV['source'])
else
  repository = ENV['gitlabSourceRepoName'].split('/').last
  tag = ENV['gitlabTargetBranch'].split('/').last
  puts "Building source for #{repository} with #{tag}"
  builder.build(repository, tag)
end
