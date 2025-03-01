# frozen_string_literal: true

desc 'Service start'
task :s, [:port, :host, :env] do |_, args|
  port = args[:port] || 3000
  host = args[:host] || 'localhost'
  env  = args[:env] || 'development'
  ENV['RACK_ENV'] = env

  exec "rackup -o #{ host } -p #{ port } -E #{ env }"
end

task service: :s

desc 'Console start'
task :c do
  require './config/application'
  Pry.start
end

task console: :c
