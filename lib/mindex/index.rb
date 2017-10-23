# frozen_string_literal: true

require 'elasticsearch'
require 'active_support/core_ext/string/inflections'

module Mindex
  module Index
    module ClassMethods
      def connection_settings(options = {})
        @connection_settings = options
      end

      def index_config(settings:, mappings:)
        @index_settings = settings
        @index_mappings = mappings
      end

      def index_prefix(prefix)
        @index_prefix = prefix
      end

      def index_label(label)
        @index_label = label
      end

      def index_num_threads(count)
        @index_num_threads = count
      end

      def index_alias
        [@index_prefix, (@index_label || name.demodulize.tableize)].compact.join('_').underscore
      end

      def index_name
        elasticsearch.indices.get_alias(name: index_alias).keys.first
      rescue ::Elasticsearch::Transport::Transport::Errors::NotFound
        nil
      end

      def doc_type
        @index_label || name.demodulize.tableize
      end

      def index_refresh
        elasticsearch.indices.refresh(index: index_name)
      end

      def index_exist?(name = nil)
        return false if name.nil? && index_name.nil?
        elasticsearch.indices.exists(index: name || index_name)
      end

      def index_create(move_or_create_index_alias: true)
        index_name = new_index_name
        elasticsearch.indices.create(index: index_name, body: { settings: @index_settings || {}, mappings: @index_mappings || {} })
        add_index_alias(target: index_name) if move_or_create_index_alias
        index_name
      end

      def reindex(options = {})
        index_create unless index_exist?
        index_queue do |queue|
          scroll(options) do |items|
            queue << items
          end
        end
      end

      def recreate_index(options = {})
        started_at = Time.now
        index_name = index_create(move_or_create_index_alias: false)
        index_queue(index: index_name) do |queue|
          scroll(options) do |items|
            queue << items
          end
        end
        add_index_alias(target: index_name)
        reindex(options.merge(started_at: started_at))
      end

      def elasticsearch
        Elasticsearch.connect(@connection_settings)
      end
      alias_method :es, :elasticsearch

      private

      def index_queue(index: nil)
        index = index || index_name
        num_threads = @index_num_threads || 4
        queue = SizedQueue.new(num_threads * 2)
        threads = num_threads.times.map do
          thread = Thread.new do
            until (items = queue.pop) == :stop
              bulk_data = []
              [items].flatten.each do |item|
                bulk_data << { index: { _index: index, _type: doc_type, _id: (item[:id] || item['id']), data: item } }
              end
              elasticsearch.indices.client.bulk(body: bulk_data)
            end
          end
          thread.abort_on_exception = true
          thread
        end

        yield queue

        index
      ensure
        num_threads.times { queue << :stop }
        threads.each(&:join)
      end

      def new_index_name
        "#{index_alias}-v#{DateTime.now.strftime('%Q')}"
      end

      def add_index_alias(target:)
        actions = [{ add: { index: target, alias: index_alias } }]

        if elasticsearch.indices.exists_alias(name: index_alias)
          actions += elasticsearch.indices.get_alias(name: index_alias).keys.map do |index_name|
            { remove: { index: index_name, alias: index_alias } }
          end
        end

        elasticsearch.indices.update_aliases(body: { actions: actions })
      end


    end

    module InstanceMethods
    end

    def self.included(receiver)
      receiver.extend ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end
