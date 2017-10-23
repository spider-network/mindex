# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'mindex'
require 'pry'

require 'sequel'
require 'sqlite3'

DB = Sequel.sqlite('tmp/database.sqlite3')

def reset_configuration!
  Mindex.configure do |config|
    config.elasticsearch_url = ENV.fetch('ELASTICSEARCH_URL', 'localhost:9200')
    config.elasticsearch_user = ENV.fetch('ELASTICSEARCH_USERNAME', 'elastic')
    config.elasticsearch_pass = ENV.fetch('ELASTICSEARCH_PASSWORD', 'changeme')
    config.elasticsearch_options = nil
  end
end

def drop_indices!
  Mindex::Elasticsearch.connect.indices.delete(index: '_all')
end

def drop_sqlite_tables!
  tables = DB[:sqlite_master].where(type: 'table').exclude(name: ['sqlite_sequence', 'sqlite_master']).select.map { |row| row[:name] }
  tables.each { |table| DB.run("DROP TABLE #{table}") }
end

RSpec.configure do |config|
  config.before(:each) do
    reset_configuration!
    drop_indices!
    drop_sqlite_tables!
  end
end
