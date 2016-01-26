require 'spec_helper'

describe Hashie::Extensions::InsensitiveAccess do
  class InsensitiveHashWithMergeInitializer < Hash
    include Hashie::Extensions::MergeInitializer
    include Hashie::Extensions::InsensitiveAccess

    class << self
      alias_method :build, :new
    end
  end

  class InsensitiveHashWithArrayInitializer < Hash
    include Hashie::Extensions::InsensitiveAccess

    class << self
      alias_method :build, :[]
    end
  end

  class InsensitiveHashWithTryConvertInitializer < Hash
    include Hashie::Extensions::InsensitiveAccess

    class << self
      alias_method :build, :try_convert
    end
  end

  class InsensitiveHashWithDash < Hashie::Dash
    include Hashie::Extensions::IndifferentAccess
    property :foo
  end

  describe 'when included in dash' do
    let(:params) { { foo: 'bar' } }
    subject { InsensitiveHashWithDash.new(params) }

    it 'initialize with a symbol' do
      expect(subject.foo).to eq params[:foo]
    end
  end

  shared_examples_for 'hash with insensitive access' do
    it 'is able to access via lowercase or uppercase' do
      h = subject.build('abc' => 123)
      expect(h['abc']).to eq 123
      expect(h['ABC']).to eq 123
    end

    describe '#values_at' do
      it 'insensitively finds values' do
        h = subject.build('foo' => 'bar', 'BAZ' => 'qux')
        expect(h.values_at('FOO', 'baz')).to eq %w(bar qux)
      end

      it 'returns the same instance of the hash that was set' do
        hash = {}
        h = subject.build('foo' => hash)
        expect(h.values_at('foo')[0]).to be(hash)
      end

      it 'returns the same instance of the array that was set' do
        array = []
        h = subject.build('foo' => array)
        expect(h.values_at('foo')[0]).to be(array)
      end

      it 'returns the same instance of the string that was set' do
        str = 'my string'
        h = subject.build('foo' => str)
        expect(h.values_at('foo')[0]).to be(str)
      end

      it 'returns the same instance of the object that was set' do
        object = Object.new
        h = subject.build('foo' => object)
        expect(h.values_at('foo')[0]).to be(object)
      end
    end

    describe '#fetch' do
      it 'works like normal fetch, but insensitive' do
        h = subject.build('foo' => 'bar')
        expect(h.fetch('foo')).to eq h.fetch('FOO')
        expect(h.fetch('foo')).to eq 'bar'
      end

      it 'returns the same instance of the hash that was set' do
        hash = {}
        h = subject.build('foo' => hash)
        expect(h.fetch('foo')).to be(hash)
      end

      it 'returns the same instance of the array that was set' do
        array = []
        h = subject.build('foo' => array)
        expect(h.fetch('foo')).to be(array)
      end

      it 'returns the same instance of the string that was set' do
        str = 'my string'
        h = subject.build('foo' => str)
        expect(h.fetch('foo')).to be(str)
      end

      it 'returns the same instance of the object that was set' do
        object = Object.new
        h = subject.build('foo' => object)
        expect(h.fetch('foo')).to be(object)
      end

      it 'yields with key name if key does not exists' do
        h = subject.build('a' => 0)
        expect(h.fetch('foo') { |key| ['default for', key] }).to eq ['default for', 'foo']
      end
    end

    describe '#delete' do
      it 'deletes insensitively' do
        h = subject.build('foo' => 'bar', 'BAZ' => 'qux')
        h.delete('FOO')
        h.delete('baz')
        expect(h).to be_empty
      end
    end

    describe '#key?' do
      let(:h) { subject.build('foo' => 'bar') }

      it 'finds it insensitively' do
        expect(h).to be_key('foo')
        expect(h).to be_key('FOO')
      end

      %w(include? member? has_key?).each do |key_alias|
        it "is aliased as #{key_alias}" do
          expect(h.send(key_alias.to_sym, 'foo')).to be(true)
          expect(h.send(key_alias.to_sym, 'FOO')).to be(true)
        end
      end
    end

    describe '#update' do
      let(:h) { subject.build('foo' => 'bar') }

      it 'allows keys to be insensitive still' do
        h.update('baz' => 'qux')
        expect(h['FOO']).to eq 'bar'
        expect(h['BAZ']).to eq 'qux'
      end

      it 'recursively injects indifference into sub-hashes' do
        h.update('baz' => { 'qux' => 'abc' })
        expect(h['BAZ']['QUX']).to eq 'abc'
      end

      it 'does not change the ancestors of the injected object class' do
        h.update('baz' => { 'qux' => 'abc' })
        expect({}).not_to be_respond_to(:indifferent_access?)
      end
    end

    describe '#replace' do
      let(:h) { subject.build('foo' => 'bar').replace('bar' => 'baz', 'hi' => 'bye') }

      it 'returns self' do
        expect(h).to be_a(subject)
      end

      it 'removes old keys' do
        ['foo', 'FOO'].each do |k|
          expect(h[k]).to be_nil
          expect(h.key?(k)).to be_falsy
        end
      end

      it 'creates new keys with indifferent access' do
        ['bar', 'BAR', 'hi', 'HI'].each { |k| expect(h.key?(k)).to be_truthy }
        expect(h['bar']).to eq 'baz'
        expect(h['BAR']).to eq 'baz'
        expect(h['hi']).to eq 'bye'
        expect(h['HI']).to eq 'bye'
      end
    end

    describe '#try_convert' do
      describe 'with conversion' do
        let(:h) { subject.try_convert('foo' => 'bar') }

        it 'is a subject' do
          expect(h).to be_a(subject)
        end
      end

      describe 'without conversion' do
        let(:h) { subject.try_convert("{ 'foo' => bar }") }

        it 'is nil' do
          expect(h).to be_nil
        end
      end
    end
  end

  describe 'with merge initializer' do
    subject { InsensitiveHashWithMergeInitializer }
    it_should_behave_like 'hash with insensitive access'
  end

  describe 'with array initializer' do
    subject { InsensitiveHashWithArrayInitializer }
    it_should_behave_like 'hash with insensitive access'
  end

  describe 'with try convert initializer' do
    subject { InsensitiveHashWithTryConvertInitializer }
    it_should_behave_like 'hash with insensitive access'
  end
end
