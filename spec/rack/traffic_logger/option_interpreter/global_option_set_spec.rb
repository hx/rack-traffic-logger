class Rack::TrafficLogger::OptionInterpreter
  describe GlobalOptionSet do

    subject { GlobalOptionSet.new }

    it 'should provide defaults' do
      expect(subject[:get][200][:requests]).to be true
      expect(subject[:put][201][:responses]).to be true
      expect(subject[:post][302][:request_headers]).to be false
      expect(subject[:patch][404][:request_bodies]).to be false
      expect(subject[:delete][415][:response_headers]).to be false
      expect(subject[:options][500][:response_bodies]).to be false
      expect(subject[:options][500][:anything_else]).to be_nil
    end

    describe 'changed defaults' do

      before { subject[nil][nil][:requests] = false }

      it 'should affect everything' do
        expect(subject[:post][201][:requests]).to be false
      end

    end

    describe 'changed code setting' do

      before :each do
        subject[nil].isolate 200
        subject[nil][200][:requests] = false
      end

      it 'should change everything for that code' do
        expect(subject[:get][200][:requests]).to be false
        expect(subject[:post][200][:requests]).to be false
      end

      it 'should change nothing for other codes' do
        expect(subject[:get][500][:requests]).to be true
        expect(subject[:post][500][:requests]).to be true
      end

    end

    describe 'changed verb setting' do

      before :each do
        subject.isolate :get
        subject[:get][nil][:requests] = false
      end

      it 'should change everything for that verb' do
        expect(subject[:get][200][:requests]).to be false
        expect(subject[:get][500][:requests]).to be false
      end

      it 'should change nothing for other verbs' do
        expect(subject[:post][200][:requests]).to be true
        expect(subject[:post][500][:requests]).to be true
      end

    end

    describe 'changed verb+code setting' do

      before do
        subject.isolate :get
        subject[:get].isolate 200
        subject[:get][200][:requests] = false
      end

      it 'should change everything for that code' do
        expect(subject[:get][200][:requests]).to be false
      end

      it 'should change nothing for other verb/code combos' do
        expect(subject[:get][500][:requests]).to be true
        expect(subject[:post][200][:requests]).to be true
        expect(subject[:post][500][:requests]).to be true
      end

    end

    describe 'isolation from defaults' do

      before do
        subject.isolate :get
        subject[nil][nil][:requests] = false
      end

      it 'should not affect defaults for the isolated verb' do
        expect(subject[:get][nil][:requests]).to be true
        expect(subject[:get][350][:requests]).to be true
      end

      it 'should affect everything else' do
        expect(subject[:post][nil][:requests]).to be false
        expect(subject[:post][350][:requests]).to be false
        expect(subject[nil][nil][:requests]).to be false
        expect(subject[nil][350][:requests]).to be false
      end

    end

    describe 'exclusivity' do

      describe 'of verbs' do
        before do
          subject.isolate :get
          subject.only_isolated!
        end

        it 'should mute non-isolated verbs' do
          expect(subject[:get][200][:requests]).to be true
          expect(subject[:put][200][:requests]).to be false
        end
      end

      describe 'of statuses' do
        before do
          subject[nil].isolate 200
          subject[nil].only_isolated!
         end

        it 'should mute non-isolated codes' do
          expect(subject[:get][200][:requests]).to be true
          expect(subject[:get][400][:requests]).to be false
        end
      end

      describe 'of statuses and codes' do
        before do
          subject.isolate :get
          subject.only_isolated!
          subject[:get].isolate 200
          subject[:get].only_isolated!
        end

        it 'should mute non-isolated codes and statuses' do
          expect(subject[:get][200][:requests]).to be true
          expect(subject[:get][400][:requests]).to be false
          expect(subject[:post][200][:requests]).to be false
          expect(subject[:post][400][:requests]).to be false
        end
      end

    end

  end
end
