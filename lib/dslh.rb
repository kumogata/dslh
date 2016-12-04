require 'dslh/version'
require 'stringio'
require 'pp'
require 'yaml'

class Dslh
  class ValidationError < StandardError
    attr_reader :errors
    attr_reader :data

    def initialize(root_errors, data)
      super(root_errors.map {|e| e.to_s }.join("\n"))
      @errors = root_errors
      @data = data
    end
  end

  INDENT_SPACES = '  '

  VALID_OPTIONS = [
    :allow_duplicate,
    :allow_empty_args,
    :conv,
    :dump_old_hash_array_format,
    :exclude_key,
    :filename,
    :force_dump_braces,
    :ignore_methods,
    :initial_depth,
    :key_conv,
    :lineno,
    :root_identify,
    :schema,
    :schema_path,
    :scope_hook,
    :scope_vars,
    :time_inspecter,
    :use_braces_instead_of_do_end,
    :value_conv,
  ]

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
      if [hash, options].any? {|i| not i.kind_of?(Hash) }
        raise TypeError, "wrong argument type #{options.class} (expected Hash)"
      end

      self.new(options).deval(hash, &block)
    end
  end # of class methods

  def initialize(options = {})
    invlid_options = options.keys - VALID_OPTIONS

    unless invlid_options.empty?
      raise ArgumentError, 'invalid option ' + invlid_options.map {|i| i.inspect }.join(',')
    end

    @options = {
      :time_inspecter => method(:inspect_time),
      :dump_old_hash_array_format => false,
      :force_dump_braces => false,
      :use_braces_instead_of_do_end => false,
    }.merge(options)

    @options[:key_conv] ||= (@options[:conv] || proc {|i| i.to_s })
    @options[:value_conv] ||= @options[:conv]
  end

  def eval(expr = nil, &block)
    retval = {}
    scope = Scope.new
    scope.instance_variable_set(:@__options__, @options)
    scope.instance_variable_set(:@__hash__, retval)
    @options[:scope_hook].call(scope) if @options[:scope_hook]

    (@options[:scope_vars] || {}).each do |name, value|
      scope.instance_variable_set("@#{name}", value)
    end

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

    if (schema = @options[:schema] || schema_path = @options[:schema_path])
      begin
        require 'kwalify'
      rescue LoadError
        raise 'cannot load "kwalify". please install "kwalify"'
      end

      if schema and not schema.kind_of?(String)
        raise TypeError, "wrong schema type #{schema.class} (expected String)"
      end

      if schema_path and not schema_path.kind_of?(String)
        raise TypeError, "wrong schema_path type #{schema_path.class} (expected String)"
      end

      schema = schema_path ? Kwalify::Yaml.load_file(schema_path) : Kwalify::Yaml.load(schema)
      validator = Kwalify::Validator.new(schema)

      if @options[:root_identify]
        new_retval = {}

        retval.each do |k, v|
          new_retval[k] = v.map {|_id, attrs|
            attrs.merge('_id' => _id)
          }
        end

        errors = validator.validate(new_retval)

        errors.each do |e|
          path = e.path.split('/', 4)[1..-1]
          root_key = path.shift
          _id = path.shift.to_i

          if _id_orig = new_retval.fetch(root_key, {})[_id]
            _id = _id_orig['_id'] || _id
          end

          path = '/' + ([root_key, _id] + path).join('/')
          e.path.replace(path)
        end
      else
        errors = validator.validate(retval)
      end

      unless errors.empty?
        raise ValidationError.new(errors, retval)
      end
    end

    return retval
  end

  def deval(hash)
    buf = StringIO.new
    depth = @options[:initial_depth] || 0
    deval0(hash, depth, buf, true)
    buf.string
  end

  private

  def deval0(hash, depth, buf, root = false)
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
        if root and @options[:root_identify] and value.kind_of?(Hash)
          value.each do |k, v|
            buf.print(indent + key + ' ' + k.inspect)
            value_proc(v, depth, buf, true, key)
          end
        else
          buf.print(indent + key)
          value_proc(value, depth, buf, true, key)
        end
      end
    end
  end

  def value_proc(value, depth, value_buf, newline = true, curr_key = nil)
    indent = (INDENT_SPACES * depth)
    next_indent = (INDENT_SPACES * (depth + 1))
    value_conv = @options[:value_conv]
    nested = false

    case value
    when Hash
      if exclude_keys?(value.keys)
        value_buf.puts('(' + ("\n" + value.pretty_inspect.strip).gsub("\n", "\n" + next_indent) + ')')
      else
        nested = true
        value_buf.puts(@options[:use_braces_instead_of_do_end] ? ' {' : ' do')
        deval0(value, depth + 1, value_buf)
        value_buf.puts(indent + (@options[:use_braces_instead_of_do_end] ? '}' : 'end'))
      end
    when Array
      if value.empty?
        value_buf.puts(" []")
      elsif value.any? {|v| [Array, Hash].any? {|c| v.kind_of?(c) }}
        nested = true

        if not @options[:dump_old_hash_array_format] and value.all? {|i| i.kind_of?(Hash) and not exclude_keys?(i.keys) }
          value_buf.puts(@options[:use_braces_instead_of_do_end] ? ' {|*|' : ' do |*|')

          value.each_with_index do |v, i|
            deval0(v, depth + 1, value_buf)

            if i < (value.length - 1)
              if @options[:use_braces_instead_of_do_end]
                value_buf.puts(indent + "}\n" + indent + curr_key + ' {|*|')
              else
                value_buf.puts(indent + "end\n" + indent + curr_key + ' do |*|')
              end
            end
          end

          if newline
            value_buf.puts(indent + (@options[:use_braces_instead_of_do_end] ? '}' : 'end'))
          else
            value_buf.print(indent + (@options[:use_braces_instead_of_do_end] ? '}' : 'end'))
          end
        else
          value_buf.puts(' [')

          value.each_with_index do |v, i|
            case v
            when Hash
              if exclude_keys?(v.keys)
                value_buf.print(INDENT_SPACES * (depth + 1) + v.pretty_inspect.strip)
              else
                value_buf.puts(next_indent + '_{')
                deval0(v, depth + 2, value_buf)
                value_buf.print(next_indent + '}')
              end
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
        end
      elsif @options[:force_dump_braces] or value.length == 1
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

      if @options[:time_inspecter] and value.kind_of?(Time)
        value = @options[:time_inspecter].call(value)
        value_buf.puts(' ' + value)
      else
        value_buf.puts(' ' + value.inspect)
      end
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

  def inspect_time(time)
    if Time.respond_to?(:parse)
      "Time.parse(#{time.to_s.inspect})"
    else
      "Time.at(#{time.tv_sec}, #{time.tv_usec})"
    end
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
      exist_value = @__hash__[method_name]

      if not @__options__[:allow_duplicate] and exist_value and not (block and block.arity == -1)
        if args.length != 1 or not nested_hash or not exist_value.kind_of?(Hash)
          raise "duplicate key #{method_name.inspect}"
        end
      end

      push_to_hash = proc do |v|
        if block and block.arity == -1
          @__hash__[method_name] ||= []
          @__hash__[method_name] << v
        else
          @__hash__[method_name] = v
        end
      end

      if args.empty?
        push_to_hash.call(nested_hash)
      else
        args = args.map {|i| value_conv.call(i) } if value_conv
        value = args.length > 1 ? args : args[0]

        if args.length == 1 and exist_value and nested_hash
          exist_value[value] = nested_hash
        elsif nested_hash
          push_to_hash.call(value => nested_hash)
        else
          push_to_hash.call(value)
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
