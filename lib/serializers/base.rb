class Serializers
  class Base
    @@structures = {}

    def self.structure(type, &blk)
      @@structures["#{name}::#{type}"] = blk
    end

    def initialize(type)
      @type = type
    end

    def serialize(object)
      object.respond_to?(:map) ? object.map { |item| serializer.call(item) } : serializer.call(object)
    end

    private

    def self.time_format(time)
      # times *must* be iso8601 but with the Z at the end for firefox
      time.getutc.iso8601
    end

    def serializer
      @@structures["#{self.class.name}::#{@type}"]
    end
  end
end
