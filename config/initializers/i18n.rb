# frozen_string_literal: true

require 'i18n'

I18n.load_path += Dir[File.expand_path('config/locales/**/*.yml')]
I18n.default_locale = :ru
I18n.backend.load_translations
