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
      elsif sys_call('rake -T | grep pkg:generate_source')
        puts "Found pkg:generate_source rake task; running rake pkg:generate_source"
        sys_call('rake pkg:generate_source')
        artifact = "pkg/#{@repository}-#{@ref}.tar.*"
      else
        puts "Building git archive tarball"
        artifact = "#{@repository}-#{@ref}.tar.bz2"
        sys_call("git archive --prefix=#{@repository}-#{@ref}/ #{@ref} | bzip2 -9 > #{artifact}")
      end

      sys_call("scp #{artifact} jenkins@#{ENV['SOURCE_FILE_HOST']}:/var/www/html/pub/sources/6.2")
    end

    cleanup
  end

  private

  def clone
    sys_call("git -c http.sslVerify=false clone https://#{ENV['GIT_HOSTNAME']}/#{ENV['GIT_ORGANIZATION']}/#{@repository}.git")
  end

  def gemspec?
    !Dir.glob('*.gemspec').empty?
  end

  def cleanup
    puts "Cleaning up #{@repository}"
    system("rm -rf #{@repository}")
    exit @exit_code
  end

  def sys_call(command)
    success = system(command)
    @exit_code = 1 if !success
    success
  end
end

builder = SourceBuilder.new(ENV['repository'], ENV['ref'])
builder.build
