require 'dslh/version'

class Dslh
  def self.eval(expr_or_options = nil, options = nil, &block)
    if options and not options.kind_of?(Hash)
      raise TypeError, "wrong argument type #{options.class} (expected Hash)"
    end

    expr = nil
    options ||= {}

    if expr_or_options
      case expr_or_options
      when String
        expr = expr_or_options
      when Hash
        options.update(expr_or_options)
      else
        raise TypeError, "wrong argument type #{expr_or_options.class} (expected String or Hash)"
      end
    end

    self.new(options).eval(expr, &block)
  end

  def initialize(options = {})
    @options = options.dup
  end

  def eval(expr = nil, &block)
    retval = {}
    scope = Scope.new
    scope.instance_variable_set(:@__options__, @options)
    scope.instance_variable_set(:@__hash__, retval)

    if expr
      eval_args = [expr]

      [:filename, :lineno].each do |k|
        eval_args << @options[k] if @options[k]
      end

      scope.instance_eval(*eval_args)
    else
      scope.instance_eval(&block)
    end

    return retval
  end

  class Scope
    def method_missing(method_name, *args, &block)
      key_conv = @__options__[:key_conv] || @__options__[:conv]
      value_conv = @__options__[:value_conv] || @__options__[:conv]

      nested_hash = block ? Dslh.eval(@__options__, &block) : nil
      method_name = key_conv.call(method_name) if key_conv

      if args.empty?
        @__hash__[method_name] = nested_hash
      else
        args = args.map {|i| value_conv.call(i) } if value_conv
        value = args.length > 1 ? args : args[0]

        if nested_hash
          @__hash__[method_name] = {
          value => nested_hash
        }
        else
          @__hash__[method_name] = value
        end

        return @__hash__
      end
    end # of Scope
  end
end
