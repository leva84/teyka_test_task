# frozen_string_literal: true

class BaseCommand
  attr_reader :errors, :args, :data_summary

  def initialize(params = {})
    @errors = []
    @args = params
    @data_summary = nil

    validate_params
  end

  def call
    raise NotImplementedError, 'Call method should be implemented in the heir'
  end

  def self.call(params = {})
    new(params).tap(&:call)
  end

  def ok?
    errors.empty?
  end

  def error?
    errors.any?
  end

  def status
    ok? ? :ok : :error
  end

  def code(value: nil)
    @code ||= value || (ok? ? 200 : 422)
  end

  def add_error(message)
    @errors << message
  end

  private

  def validate_params; end
end
