#!/usr/bin/env ruby

# load freshmeat bindings
require '../freshmeat'

# list of keys to extract from project
PROJ_KEYS = %w{projectname_full projectname_short project_version}

# check command-line arguments
unless ARGV.size >= 2
  $stderr.puts "Usage: #$0 [user] [pass]"
  exit -1
end

# connect to freshmeat
Freshmeat.new(*ARGV) do |fm|
  # get a list of projects
  projects = fm.projects
  
  # iterate over the list and print each one out
  projects.each do |project|
    puts '%s (%s): version %s' % PROJ_KEYS.map { |key| project[key] }
  end
end
