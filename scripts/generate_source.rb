#!/usr/bin/env ruby

class SourceBuilder

  attr_accessor :repository, :ref, :exit_code

  def initialize(repository, ref)
    self.repository = repository
    self.ref = ref
    self.exit_code = 0
  end

  def build
    clone

    Dir.chdir(@repository) do
      sys_call("git -c http.sslVerify=false fetch origin")
      sys_call("git checkout #{@ref}")

      if gemspec?
        puts "Found gemspec; building gem"
        sys_call("gem build *.gemspec")
        artifact = "#{@repository}-*.gem"
      elsif File.exists?('Rakefile') && sys_call('rake -T | grep pkg:generate_source')
        puts "Found pkg:generate_source rake task; running rake pkg:generate_source"
        sys_call('rake pkg:generate_source')
        artifact = "pkg/#{@repository}-#{@ref}.tar.*"
      else
        puts "Building git archive tarball"
        artifact = "#{@repository}-#{@ref}.tar.bz2"
        sys_call("git archive --prefix=#{@repository}-#{@ref}/ #{@ref} | bzip2 -9 > #{artifact}")
      end

      scp_artifact(artifact)
    end

    cleanup(@repository)
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

  def cleanup(files)
    puts "Cleaning up #{files}"
    system("rm -rf #{files}")
    exit @exit_code
  end

  def sys_call(command)
    success = system(command)
    @exit_code = 1 if !success
    success
  end
end

builder = SourceBuilder.new(ENV['repository'], ENV['ref'])

if ENV['source']
  builder.upload(ENV['source'])
else
  builder.build
end
