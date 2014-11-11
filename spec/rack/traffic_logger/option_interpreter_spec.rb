class Rack::TrafficLogger
  describe OptionInterpreter do

    class IExpect

      VERBS = %i[get post put patch delete head options trace]
      FLAGS = %i[request_headers request_bodies response_headers response_bodies]

      VERBS.each do |verb|
        define_method verb do |*args|
          code = Fixnum === args.first && args.shift
          subject = @options
          message = "a #{verb.to_s.upcase} request"
          message << " with a #{code} response" if code
          message << ' should log '
          case args.first
            when true then message << 'default data'
            when false then message << 'nothing'
            when :all then message << 'everything'
            else message << args.join(', ').gsub('_', ' ')
          end
          @context.it message do
            case args.first
              when true, false
                expect(subject.basic? verb, code).to be args.first
                FLAGS.each { |flag| expect(subject.__send__ :"#{flag}?", verb, code).to be false }
              when :all
                expect(subject.basic? verb, code).to be true
                FLAGS.each { |flag| expect(subject.__send__ :"#{flag}?", verb, code).to be true }
              else
                expect(subject.basic? verb, code).to be true
                FLAGS.each { |flag| expect(subject.__send__ :"#{flag}?", verb, code).to be args.include? flag }
            end
          end
        end
      end

      def initialize(args, context)
        @args = args
        @context = context
        @options = OptionInterpreter.new *args
      end

      def any(*args)
        VERBS.each { |verb| __send__ verb, *args }
      end

    end

    def self.with_args(*args)
      describe "with arguments #{args}" do
        i = IExpect.new(args, self)
        yield i
      end
    end

    describe 'shorthand' do

      subject { OptionInterpreter.new 200 => :all, 300 => false }

      it 'should provide shorthand methods' do
        expect(subject.basic? :get, 200).to be subject.for(:get, 200).basic?
        expect(subject.response_bodies? :get, 400).to be subject.for(:get, 400).response_bodies?
      end

    end

    describe 'argument combinations' do

      with_args do |i|
        i.any true
      end

      with_args get: false do |i|
        i.put true
        i.post true
        i.get false
        i.patch true
        i.delete true
      end

      with_args :response_headers, :response_bodies do |i|
        i.any :response_headers, :response_bodies
      end

      with_args :request_bodies do |i|
        i.any :request_bodies
      end

      with_args get: :request_headers, 400...600 => :all do |i|
        i.post true
        i.get :request_headers
        i.get 405, :all
        i.post 200, true
        i.post 500, :all
      end

      with_args post: [:request_bodies, :response_headers], delete: :all, 300...400 => false do |i|
        i.post 201, :request_bodies, :response_headers
        i.delete 204, :all
        i.post 400, :request_bodies, :response_headers
        i.get 301, false
        i.get 200, true
      end

      with_args post: {400...600 => :all} do |i|
        i.get true
        i.patch true
        i.delete true
        i.post 201, true
        i.post 500, :all
      end

      with_args post: {only: {400...600 => :response_bodies}} do |i|
        i.get true
        i.patch true
        i.delete true
        i.post 201, false
        i.post 500, :response_bodies
      end

      with_args only: {post: {only: {400...600 => [:response_bodies, :response_headers]}}} do |i|
        i.get false
        i.patch false
        i.delete false
        i.post 201, false
        i.post 500, :response_bodies, :response_headers
      end

      with_args :put, :patch do |i|
        i.get false
        i.post false
        i.put true
        i.patch true
      end

      with_args 301, 400...600 do |i|
        i.get 200, false
        i.put 300, false
        i.patch 301, true
        i.post 400, true
        i.delete 500, true
      end

    end

  end
end
