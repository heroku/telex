module Telex
  module Sample
    #
    # Used to increment to a counter metric.
    #
    # Sample.count "metric.count"
    # Sample.count "metric.count", "metric.eu.count"
    # Sample.count "metric.count", value: 3
    #
    def self.count(*names)
      options = names.last.is_a?(Hash) ? names.pop : {}

      # default count is 1
      value = options[:value] || 1

      # like: count.prefix.name1=val1 count.prefix.name2=val2
      measures = names.map { |n| ["count##{prefix}.#{n}", value] }.to_h
      Pliny.log(measures)

      nil
    end

    #
    # Used to make an aggregate measurement. Produces metrics like median, p95,
    # and p99.
    #
    # Sample.measure "metric.elapsed" { do_work }
    # Sample.measure "metric.elapsed", "metric.eu.elapsed" { do_work }
    # Sample.measure "metric.elapsed", value: 0.003
    # Sample.measure "metric.elapsed", value: 3, units: "ms"
    #
    def self.measure(*names, &block)
      options = names.last.is_a?(Hash) ? names.pop : {}

      units = block ? "s" : options[:units] || ""

      value, return_value = block ? time(&block) : [options[:value], nil]
      display = units ? "#{value}#{units}" : value

      # like: measure.prefix.name1=val1 measure.prefix.name2=val2
      measures = names.map { |n| ["measure##{prefix}.#{n}", display] }.to_h
      Pliny.log(measures)

      return_value
    end

    #
    # Used to sample a single value. This is useful when you're already
    # producing an aggregate, and just need to convey it to the metrics
    # service.
    #
    # Sample.measure "metric.rate", value: 23
    # Sample.measure "metric.rate", value: 23, units: "events/s"
    #
    def self.sample(*names)
      options = names.last.is_a?(Hash) ? names.pop : {}

      units = options[:units] || ""

      value = options[:value] || raise("need value for sample")
      display = units ? "#{value}#{units}" : value

      # like: sample.prefix.name1=val1 sample.prefix.name2=val2
      measures = names.map { |n| ["sample##{prefix}.#{n}", display] }.to_h
      Pliny.log(measures)

      # like: source=heroku.com measure.api.name1=val1 measure.api.name2=val2
      # measures = Hash[names.map { |n| ["measure.api.#{n}", display] }]
      # measures['source'] = Utils.heroku_domain
      # API.log(measures)

      nil
    end

    private

    def self.prefix
      @@prefix ||= "telex.#{Config.console_banner || "production"}"
    end

    def self.time(&block)
      start = Time.now
      return_value = block.call
      [(Time.now - start).to_f, return_value]
    end
  end
end
