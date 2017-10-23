# frozen_string_literal: true

describe Mindex::Elasticsearch do
  subject(:connect) { described_class.connect }

  describe '.connect' do
    before do
      allow(::Elasticsearch::Client).to receive(:new)
    end

    it 'creates a Elasticsearch::Client instance' do
      connect
      expect(::Elasticsearch::Client).to have_received(:new)
    end

    context 'when elasticsearch_url is set to "foo"' do
      before { Mindex.config.elasticsearch_url = 'foo' }

      it do
        connect
        expect(::Elasticsearch::Client).to have_received(:new).with(hash_including(url: 'foo'))
      end
    end

    context 'when elasticsearch_user is set' do
      before { Mindex.config.elasticsearch_user = 'username' }

      it do
        connect
        expect(::Elasticsearch::Client).to have_received(:new).with(hash_including(user: 'username'))
      end
    end

    context 'when elasticsearch_pass is set' do
      before { Mindex.config.elasticsearch_pass = 'password' }

      it do
        connect
        expect(::Elasticsearch::Client).to have_received(:new).with(hash_including(password: 'password'))
      end
    end

    context 'when elasticsearch_options is set' do
      before { Mindex.config.elasticsearch_options = { url: 'local', foo: 'bar' } }

      it do
        connect
        expect(::Elasticsearch::Client).to have_received(:new).with(hash_including(url: 'local', foo: 'bar'))
      end
    end
  end

  describe '.version' do
    before do
      client =  instance_double(Elasticsearch::Transport::Client, info: { 'version' => { 'number' => '6.6.6' } })
      allow(::Elasticsearch::Client).to receive(:new).and_return(client)
    end

    it 'returns the elasticsearch cluster version' do
      expect(connect.version).to eq '6.6.6'
    end
  end

  describe '.version_gte' do
    before do
      client =  instance_double(Elasticsearch::Transport::Client, info: { 'version' => { 'number' => '6.6.6' } })
      allow(::Elasticsearch::Client).to receive(:new).and_return(client)
    end

    context 'when expected version is smaller' do
      it { expect(connect.version_gte?('0.90.0')).to be true }
    end

    context 'when expected version is equal' do
      it { expect(connect.version_gte?('6.6.6')).to be true }
    end

    context 'when expected version is greater' do
      it { expect(connect.version_gte?('7.0.0')).to be false }
    end
  end
end
