# frozen_string_literal: true

env = ENV.fetch('RACK_ENV', 'development')
db_config = YAML.load_file(File.expand_path('../database.yml', __dir__), aliases: true)

adapter = db_config[env]['adapter']
database = db_config[env]['database']

raise 'Database adapter or database_name is missing!' unless adapter && database

user = db_config[env]['user']
password = db_config[env]['password']

raise 'Database user or password is missing!' unless user && password

DB = Sequel.connect(
  adapter: adapter,
  database: database,
  user: user,
  password: password,
  host: db_config[env]['host'] || 'localhost',
  port: db_config[env]['port'] || 5432
)
