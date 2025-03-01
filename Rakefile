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

namespace :db do
  require './config/application'
  require 'sequel/extensions/migration'

  migrations_path = File.expand_path('db/migrations', __dir__)

  desc 'DB migrate'
  task :migrate, [:env] do |_, args|
    ENV['RACK_ENV'] = args[:env] || 'development'
    db = Sequel.connect("sqlite://db/#{ ENV.fetch('RACK_ENV') }.db")

    puts "The use of migrations from #{ migrations_path }..."
    Sequel::Migrator.run(db, migrations_path)
    puts 'Migrations are successfully applied.'

    Rake::Task['db:dump_schema'].invoke
  end

  desc 'Export the current scheme in db/schem.sql'
  task :dump_schema do
    if ENV['RACK_ENV'] == 'development'
      puts 'Export scheme to db/schema.sql ...'
      `sqlite3 db/development.db .schema > db/schema.sql`
      puts 'The scheme is successfully exported to db/Schema.sql.'
    else
      puts 'Skipping schema export as it is only allowed in the development environment.'
    end
  end

  desc 'Drop the database for the current environment'
  task :drop, [:env] do |_, args|
    env = args[:env] || 'development'
    ENV['RACK_ENV'] = env

    db_config = YAML.load_file('config/database.yml', aliases: true)[env]

    db_path = db_config['database']
    adapter = db_config['adapter']

    if adapter == 'sqlite'
      if File.exist?(db_path)
        puts "Dropping database: #{db_path}..."
        FileUtils.rm(db_path)
        puts 'Database dropped successfully.'
      else
        puts "Database does not exist: #{db_path}"
      end
    else
      puts "Unsupported adapter: #{adapter}"
    end
  end
end
