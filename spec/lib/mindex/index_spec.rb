# frozen_string_literal: true

require 'dummy/index/event'

describe Mindex::Index do
  let(:index_klass) { Index::Event }

  describe '.index_alias' do
    it 'returns the alias name of the index' do
      expect(index_klass.index_alias).to eq 'events'
    end

    context 'when prefix is definde' do
      let(:prefix) { 'foobar' }
      before { index_klass.index_prefix(prefix) }

      it 'prefixes the alias name' do
        expect(index_klass.index_alias).to eq "#{prefix}_events"
      end

      after { index_klass.index_prefix(nil) }
    end

    context 'when label is definde' do
      let(:label) { 'competition' }
      before { index_klass.index_label(label) }

      it 'uses the label instead of the tableize class name' do
        expect(index_klass.index_alias).to eq label
      end

      after { index_klass.index_label(nil) }
    end
  end

  describe '.doc_type' do
    it 'uses the tableize class name' do
      expect(index_klass.doc_type).to eq index_klass.name.demodulize.tableize
    end

    context 'when label is definde' do
      let(:label) { 'competition' }
      before { index_klass.index_label(label) }

      it 'uses the label instead of the tableize class name' do
        expect(index_klass.doc_type).to eq label
      end

      after { index_klass.index_label(nil) }
    end
  end

  describe '.index_name' do
    context 'when index does not exists' do
      it do
        expect(index_klass.index_name).to be_nil
      end
    end

    context 'when index exists' do
      before do
        @index_name = index_klass.index_create
      end

      it 'returns the index name' do
        expect(index_klass.index_name).to eq @index_name
      end
    end
  end

  describe '.index_refresh' do
    context 'when index does not exists' do
      it do
        expect { index_klass.index_refresh }.not_to raise_error
      end
    end

    context 'when index exists' do
      before { index_klass.index_create }

      it do
        expect { index_klass.index_refresh }.not_to raise_error
      end
    end
  end

  describe '.index_exist?' do
    context 'when the index does not exists' do
      it do
        expect(index_klass.index_exist?).to be false
      end
    end

    context 'when the index exists' do
      before { index_klass.index_create }

      it do
        expect(index_klass.index_exist?).to be true
      end
    end
  end

  describe '.connection_settings' do

  end

  describe '.index_config' do
    let(:settings) { { foo: :bar } }
    let(:mapping) { { bar: :foo } }

    before do
      @indices = instance_double(Elasticsearch::API::Indices::IndicesClient, create: nil)
      allow(::Elasticsearch::Client).to receive(:new).and_return(instance_double(Elasticsearch::Transport::Client, indices: @indices))

      index_klass.index_config(settings: settings, mappings: mapping)
    end

    it 'creates the index with the given settings and mappings' do
      index_klass.index_create(move_or_create_index_alias: false)
      expect(@indices).to have_received(:create).with(hash_including(index: anything, body: { settings: settings, mappings: mapping}))
    end

    after { index_klass.index_config(settings: nil, mappings: nil) }
  end

  describe '.reindex' do
    let(:event) { { 'id' => 1, 'name' => 'BerlinMan' } }

    before do
      DB.run "CREATE TABLE events (id integer primary key autoincrement, name varchar(255))"
      DB[:events].insert(event)
    end

    it 'updates the entities' do
      index_klass.reindex
      expect(index_klass.es.get(index: index_klass.index_alias, id: event['id'])['_source']).to eq event
      DB[:events].where(id: event['id']).update(name: 'BerlinMan 2018')
      index_klass.reindex
      expect(index_klass.es.get(index: index_klass.index_alias, id: event['id'])['_source']['name']).to eq 'BerlinMan 2018'
    end
  end

  describe '.recreate_index' do
    let(:event) { { 'id' => 1, 'name' => 'BerlinMan' } }

    before do
      DB.run "CREATE TABLE events (id integer primary key autoincrement, name varchar(255))"
      DB[:events].insert(event)
    end

    it 'inserts the entities in a new index' do
      index_name = index_klass.recreate_index
      expect(index_klass.es.get(index: index_name, id: event['id'])['_source']).to eq event
    end
  end
end
