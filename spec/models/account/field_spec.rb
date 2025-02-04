require 'rails_helper'

RSpec.describe Account::Field, type: :model do
  describe '#verified?' do
    let(:account) { double('Account', local?: true) }

    subject { described_class.new(account, 'name' => 'Foo', 'value' => 'Bar', 'verified_at' => verified_at) }

    context 'when verified_at is set' do
      let(:verified_at) { Time.now.utc.iso8601 }

      it 'returns true' do
        expect(subject.verified?).to be true
      end
    end

    context 'when verified_at is not set' do
      let(:verified_at) { nil }

      it 'returns false' do
        expect(subject.verified?).to be false
      end
    end
  end

  describe '#mark_verified!' do
    let(:account) { double('Account', local?: true) }
    let(:original_hash) { { 'name' => 'Foo', 'value' => 'Bar' } }

    subject { described_class.new(account, original_hash) }

    before do
      subject.mark_verified!
    end

    it 'updates verified_at' do
      expect(subject.verified_at).to_not be_nil
    end

    it 'updates original hash' do
      expect(original_hash['verified_at']).to_not be_nil
    end
  end

  describe '#verifiable?' do
    let(:account) { double('Account', local?: local) }

    subject { described_class.new(account, 'name' => 'Foo', 'value' => value) }

    context 'for local accounts' do
      let(:local) { true }

      context 'for a URL with misleading authentication' do
        let(:value) { 'https://spacex.com                                                                                            @h.43z.one' }

        it 'returns false' do
          expect(subject.verifiable?).to be false
        end
      end

      context 'for a URL' do
        let(:value) { 'https://example.com' }

        it 'returns true' do
          expect(subject.verifiable?).to be true
        end
      end

      context 'for text that is not a URL' do
        let(:value) { 'Hello world' }

        it 'returns false' do
          expect(subject.verifiable?).to be false
        end
      end

      context 'for text that contains a URL' do
        let(:value) { 'Hello https://example.com world' }

        it 'returns false' do
          expect(subject.verifiable?).to be false
        end
      end
    end

    context 'for remote accounts' do
      let(:local) { false }

      context 'for a link' do
        let(:value) { '<a href="https://www.patreon.com/mastodon" target="_blank" rel="nofollow noopener noreferrer me"><span class="invisible">https://www.</span><span class="">patreon.com/mastodon</span><span class="invisible"></span></a>' }

        it 'returns true' do
          expect(subject.verifiable?).to be true
        end
      end

      context 'for a link with misleading authentication' do
        let(:value) { '<a href="https://google.com                                                                                            @h.43z.one" target="_blank" rel="nofollow noopener noreferrer me"><span class="invisible">https://</span><span class="">google.com</span><span class="invisible">                                                                                            @h.43z.one</span></a>' }

        it 'returns false' do
          expect(subject.verifiable?).to be false
        end
      end

      context 'for HTML that has more than just a link' do
        let(:value) { '<a href="https://google.com" target="_blank" rel="nofollow noopener noreferrer me"><span class="invisible">https://</span><span class="">google.com</span><span class="invisible"></span></a>                                                                                            @h.43z.one' }

        it 'returns false' do
          expect(subject.verifiable?).to be false
        end
      end

      context 'for a link with different visible text' do
        let(:value) { '<a href="https://google.com/bar">https://example.com/foo</a>' }

        it 'returns false' do
          expect(subject.verifiable?).to be false
        end
      end

      context 'for text that is a URL but is not linked' do
        let(:value) { 'https://example.com/foo' }

        it 'returns false' do
          expect(subject.verifiable?).to be false
        end
      end
    end
  end
end
