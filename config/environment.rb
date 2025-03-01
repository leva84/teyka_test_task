# frozen_string_literal: true

require 'json'
require 'pry'
require 'sequel'
require 'sinatra'
require 'sinatra/base'
require 'yaml'

Dir[File.join(__dir__, './initializers/**/*.rb')].each { |file| require file }
Dir[File.join(__dir__, '../app/helpers/**/*.rb')].each { |file| require file }
Dir[File.join(__dir__, '../app/models/**/*.rb')].each { |file| require file }
Dir[File.join(__dir__, '../app/controllers/**/*.rb')].each { |file| require file }
