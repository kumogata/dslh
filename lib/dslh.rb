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
    @options[:key_conv] ||= (@options[:conv] || proc {|i| i.to_s })
    @options[:value_conv] ||= @options[:conv]
  end

  def eval(expr = nil, &block)
    retval = {}
    scope = Scope.new
    scope.instance_variable_set(:@__options__, @options)
    scope.instance_variable_set(:@__hash__, retval)
    @options[:scope_hook].call(scope) if @options[:scope_hook]

    if @options[:ignore_methods]
      ignore_methods = Array(@options[:ignore_methods])

      ignore_methods.each do |method_name|
        scope.instance_eval(<<-EOS)
          def #{method_name}(*args, &block)
            method_missing(#{method_name.to_s.inspect}, *args, &block)
          end
        EOS
      end
    end

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
    key_conv = @options[:key_conv]
    value_conv = @options[:value_conv]

    if exclude_keys?(hash.keys)
      buf.puts('(' + ("\n" + hash.pretty_inspect.strip).gsub("\n", "\n" + indent) + ')')
      return
    end

    hash.each do |key, value|
      key = key_conv.call(key) if key_conv

      if key.kind_of?(Proc)
        tmp_buf = StringIO.new
        nested = value_proc(value, depth, tmp_buf)

        key_value = case key.arity
                    when 0
                      key.call
                    when 1
                      key.call(tmp_buf.string.strip)
                    else
                      key.call(tmp_buf.string.strip, nested)
                    end

        buf.puts(indent + key_value)
      else
        buf.print(indent + key)
        value_proc(value, depth, buf)
      end
    end
  end

  def value_proc(value, depth, value_buf, newline = true)
    indent = (INDENT_SPACES * depth)
    next_indent = (INDENT_SPACES * (depth + 1))
    value_conv = @options[:value_conv]
    nested = false

    case value
    when Hash
      if exclude_keys?(value.keys) or value.values.any? {|v| v == [] }
        value_buf.puts('(' + ("\n" + value.pretty_inspect.strip).gsub("\n", "\n" + next_indent) + ')')
      else
        nested = true
        value_buf.puts(' do')
        deval0(value, depth + 1, value_buf)
        value_buf.puts(indent + 'end')
      end
    when Array
      if value.any? {|v| [Array, Hash].any? {|c| v.kind_of?(c) }}
        nested = true
        value_buf.puts(' [')

        value.each_with_index do |v, i|
          case v
          when Hash
            value_buf.puts(next_indent + '_{')
            deval0(v, depth + 2, value_buf)
            value_buf.print(next_indent + '}')
          when Array
            value_buf.print(next_indent.slice(0...-1))
            value_proc(v, depth + 1, value_buf, false)
          else
            value_buf.print(next_indent + v.pretty_inspect.strip.gsub("\n", "\n" + next_indent))
          end

          value_buf.puts(i < (value.length - 1) ? ',' : '')
        end

        if newline
          value_buf.puts(indent + ']')
        else
          value_buf.print(indent + ']')
        end
      elsif value.length == 1
        value_buf.puts(' ' + value.inspect)
      else
        value_buf.puts(' ' + value.map {|v|
          v = value_conv.call(v) if value_conv

          if v.kind_of?(Hash)
            '(' + v.inspect + ')'
          else
            v.inspect
          end
        }.join(', '))
      end
    else
      value = value_conv.call(value) if value_conv
      value_buf.puts(' ' + value.inspect)
    end

    return nested
  end

  def exclude_keys?(keys)
    key_conv = @options[:key_conv]

    exclude_key = @options[:exclude_key] || proc {|k|
      k = key_conv.call(k) if key_conv
      k.to_s !~ /\A[_a-z]\w+\Z/i
    }

    keys.any? {|k| exclude_key.call(k) }
  end

  class Scope
    def _(key = nil, &block)
      nested_hash = ScopeBlock.nest(binding, 'block')

      if key
        key_conv = @__options__[:key_conv]
        key = key_conv.call(key) if key_conv

        if not @__options__[:allow_duplicate] and @__hash__.has_key?(key)
          raise "duplicate key #{key.inspect}"
        end

        @__hash__[key] = nested_hash
      else
        return nested_hash
      end
    end

    def method_missing(method_name, *args, &block)
      if args.empty? and not block and not @__options__[:allow_empty_args]
        super
      end

      key_conv = @__options__[:key_conv]
      value_conv = @__options__[:value_conv]
      nested_hash = block ? ScopeBlock.nest(binding, 'block', method_name) : nil
      method_name = key_conv.call(method_name) if key_conv

      if not @__options__[:allow_duplicate] and @__hash__.has_key?(method_name)
        raise "duplicate key #{method_name.inspect}"
      end

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

  class ScopeBlock
    def self.nest(bind, block_var, key = nil)
      block_call = nil

      if key
        block_call = <<-EOS
          #{block_var}_ = proc do
            if #{block_var}.arity.zero?
              #{block_var}.call
            else
              #{block_var}.call(#{key.inspect})
            end
          end

          self.instance_eval(&#{block_var}_)
        EOS
      else
        block_call = <<-EOS
          self.instance_eval(&#{block_var})
        EOS
      end

      eval(<<-EOS, bind)
        if #{block_var}
          __hash_orig = @__hash__
          @__hash__ = {}
          #{block_call}
          __nested_hash = @__hash__
          @__hash__ = __hash_orig
          __nested_hash
        else
          nil
        end
      EOS
    end
  end
end
