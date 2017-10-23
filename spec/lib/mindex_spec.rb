# frozen_string_literal: true

describe Mindex do
  it 'defines a version number' do
    expect(described_class::VERSION).to be > '0.0.0'
  end
end
