# frozen_string_literal: true

require_relative 'environment'

class TeykaApp < Sinatra::Base
  configure do
    set :root, File.dirname(__FILE__)
  end

  # Настройка JSON
  before do
    content_type :json
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
  end

  # Отправка CORS-запросов
  options '*' do
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
    halt 200
  end

  # Используем контроллеры
  CONTROLLERS.each do |controller_name|
    klass = Object.const_get(controller_name)
    use klass
  rescue NameError => e
    warn "Cannot load controller #{controller_name}: #{e.message}"
  end
end
