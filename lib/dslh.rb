require 'dslh/version'

class Dslh
  def self.eval(options = {}, &block)
    self.new(options).eval(&block)
  end

  def initialize(options = {})
    @options = options
    @hash = {}
  end

  def eval(&block)
    self.instance_eval(&block)
    return @hash
  end

  def method_missing(method_name, *args, &block)
    key_conv = @options[:key_conv] || @options[:conv]
    value_conv = @options[:value_conv] || @options[:conv]

    nested_hash = block ? self.class.eval(@options, &block) : nil
    method_name = key_conv.call(method_name) if key_conv

    if args.empty?
      @hash[method_name] = nested_hash
    else
      value = args.length > 1 ? args : args[0]
      value = value_conv.call(value) if value_conv

      if nested_hash
        @hash[method_name] = {
          value => nested_hash
        }
      else
        @hash[method_name] = value
      end
    end
  end
end
