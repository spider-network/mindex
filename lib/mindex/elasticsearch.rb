# frozen_string_literal: true

require 'elasticsearch'

module Mindex
  class Elasticsearch < Delegator
    def self.connect(options = {})
      new({
        url:      Mindex.config.elasticsearch_url,
        user:     Mindex.config.elasticsearch_user,
        password: Mindex.config.elasticsearch_pass
      }.merge(Mindex.config.elasticsearch_options || {}).merge(options || {}))
    end

    def version
      info['version']['number']
    end

    def version_gte?(expected_version)
      Gem::Version.new(version) >= Gem::Version.new(expected_version)
    end

    def initialize(options)
      @delegate_sd_obj ||= ::Elasticsearch::Client.new(options)
    end

    def __getobj__
      @delegate_sd_obj
    end

    def __setobj__(obj)
      @delegate_sd_obj = obj
    end
  end
end
