module Rack
  class TrafficLogger
    describe Formatter do
      it 'should require subclasses to implement #format(hash)' do
        expect(subject.method(:format).arity).to be 1
        expect { subject.format nil }.to raise_error { NotImplementedError }
      end
    end
  end
end