#!/usr/bin/env ruby

def gemspec?
  !Dir.glob('*.gemspec').empty?
end

system("git -c http.sslVerify=false clone https://#{ENV['GIT_HOSTNAME']}/#{ENV['GIT_ORGANIZATION']}/#{ENV['repository']}.git")

Dir.chdir(ENV['repository']) do
  system("git -c http.sslVerify=false fetch origin")
  system("git checkout #{ENV['ref']}")

  if gemspec?
    system("gem build *.gemspec")
    artifact = "#{ENV['repository']}-*.gem"
  else
    artifact = "#{ENV['repository']}-#{ENV['ref']}.tar.bz2"
    system("git archive | bzip2 -9 > #{artifact}")
  end

  system("scp #{artifact} jenkins@#{ENV['SOURCE_FILE_HOST']}:/var/www/html/pub/sources/6.2")
end

system("rm -rf #{ENV['repository']}")
