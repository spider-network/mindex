# frozen_string_literal: true

require 'mindex/version'
require 'mindex/elasticsearch'
require 'mindex/index'
require 'ostruct'

module Mindex
  class << self
    attr_writer :config
  end

  def self.config
    @config ||= OpenStruct.new
  end

  def self.configure
    yield(config)
  end
end
