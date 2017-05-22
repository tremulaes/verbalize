module Verbalize
  class Build
    def self.call(required_keywords = [], optional_keywords = [])
      new(required_keywords, optional_keywords).call
    end

    def initialize(required_keywords, optional_keywords)
      @required_keywords  = required_keywords
      @optional_keywords  = optional_keywords.reject { |key| key.is_a?(Hash) }
      @defaulted_keywords = optional_keywords.select { |key| key.is_a?(Hash) }.reduce(&:merge) || {}
    end

    def call
      # We have to re-alias `!` to `call!` here, otherwise it will be pointing
      # to the original `call!` method
      <<-CODE
class << self
  def call(#{declaration_arguments_string})
    __proxied_call(#{forwarding_arguments_string})
  end

  def call!(#{declaration_arguments_string})
    __proxied_call!(#{forwarding_arguments_string})
  end
  alias_method :!, :call!
end

def initialize(#{declaration_arguments_string})
  #{initialize_body}
end

private

attr_reader #{attribute_readers_string}
      CODE
    end

    attr_reader :required_keywords, :optional_keywords, :defaulted_keywords

    private

    def all_keywords
      required_keywords + optional_keywords + defaulted_keywords.keys
    end

    def declaration_arguments_string
      required_segments  = required_keywords.map { |keyword| "#{keyword}:" }
      optional_segments  = optional_keywords.map { |keyword| "#{keyword}: nil" }
      defaulted_segments = defaulted_keywords.keys.map { |keyword| "#{keyword}: self.defaults[:#{keyword}].call"}
      (required_segments + optional_segments + defaulted_segments).join(', ')
    end

    def forwarding_arguments_string
      all_keywords.map { |keyword| "#{keyword}: #{keyword}" }.join(', ')
    end

    def initialize_body
      all_keywords.map { |keyword| "@#{keyword} = #{keyword}" }.join("\n  ")
    end

    def attribute_readers_string
      all_keywords.map { |keyword| ":#{keyword}" }.join(', ')
    end
  end
end
