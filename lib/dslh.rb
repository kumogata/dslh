require 'dslh/version'
require 'stringio'
require 'pp'

class Dslh
  INDENT_SPACES = '  '

  class << self
    def eval(expr_or_options = nil, options = nil, &block)
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

    def deval(hash, options = {}, &block)
      if [hash, options].all? {|i| not i.kind_of?(Hash) }
        raise TypeError, "wrong argument type #{options.class} (expected Hash)"
      end

      self.new(options).deval(hash, &block)
    end
  end # of class methods

  def initialize(options = {})
    @options = options.dup
  end

  def eval(expr = nil, &block)
    retval = {}
    scope = Scope.new
    scope.instance_variable_set(:@__options__, @options)
    scope.instance_variable_set(:@__hash__, retval)
    @options[:scope_hook].call(scope) if @options[:scope_hook]

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

  def deval(hash)
    buf = StringIO.new
    deval0(hash, 0, buf)
    buf.string
  end

  private

  def deval0(hash, depth, buf)
    indent = (INDENT_SPACES * depth)
    next_indent = (INDENT_SPACES * (depth + 1))
    key_conv = @options[:key_conv] || @options[:conv]
    value_conv = @options[:value_conv] || @options[:conv]

    if exclude_key?(key_conv, hash.keys)
      buf.puts '(' + ("\n" + hash.pretty_inspect.strip).gsub("\n", "\n" + indent) + ')'
      return
    end

    hash.each do |key, value|
      key = key_conv.call(key) if key_conv
      buf.print(indent + key)

      case value
      when Hash
        if exclude_key?(key_conv, value.keys)
          buf.puts '(' + ("\n" + value.pretty_inspect.strip).gsub("\n", "\n" + next_indent) + ')'
        else
          buf.puts(' do')
          deval0(value, depth + 1, buf)
          buf.puts(indent + 'end')
        end
      when Array
        if value.any? {|v| [Array, Hash].any? {|c| v.kind_of?(c) }}
          buf.puts '(' + ("\n" + value.pretty_inspect.strip).gsub("\n", "\n" + next_indent) + ')'
        else
          buf.puts ' ' + value.map {|v|
            v = value_conv.call(v) if value_conv

            if v.kind_of?(Hash)
              '(' + v.inspect + ')'
            else
              v.inspect
            end
          }.join(', ')
        end
      else
        value = value_conv.call(value) if value_conv
        buf.puts ' ' + value.inspect
      end
    end
  end

  def exclude_key?(key_conv, keys)
    exclude_key = @options[:exclude_key] || proc {|k| k.to_s !~ /\A[_a-z]\w+\Z/i }
    exclude_key and (key_conv ? keys.map {|k| key_conv.call(k) } : keys).any? {|k| exclude_key.call(k) }
  end

  class Scope
    def method_missing(method_name, *args, &block)
      key_conv = @__options__[:key_conv] || @__options__[:conv]
      value_conv = @__options__[:value_conv] || @__options__[:conv]

      nested_hash = nil

      if block
        hash_orig = @__hash__
        @__hash__ = {}
        self.instance_eval(&block)
        nested_hash = @__hash__
        @__hash__ = hash_orig
      end

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
    end
  end # of Scope
end
