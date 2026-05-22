# frozen_string_literal: true

module EvoExtensionPoints
  # Plugin loader extension point. Community default: an in-memory registry
  # that accepts registrations and invokes on_boot callbacks, but ships with
  # zero registered plugins. See EXTENSION_POINTS.md.
  module PluginLoader
    class PluginRegistration
      attr_reader :id

      def initialize(id)
        @id = id
        @on_boot_callbacks = []
        @routes_callbacks = []
      end

      def on_boot(&block)
        @on_boot_callbacks << block if block
        self
      end

      def routes(&block)
        @routes_callbacks << block if block
        self
      end

      def invoke_on_boot!
        @on_boot_callbacks.each(&:call)
      end

      def routes_callbacks
        @routes_callbacks.dup
      end
    end

    class << self
      def register_plugin(name)
        sym = name.to_sym
        registration = PluginRegistration.new(sym)
        yield(registration) if block_given?
        registry[sym] = registration
        registration
      end

      def plugins
        registry.keys.dup
      end

      def registration(name)
        registry[name.to_sym]
      end

      def load_all
        registry.each_value(&:invoke_on_boot!)
        nil
      end

      # Host-side counterpart of load_all for the `routes` lifecycle hook.
      # The host calls this from inside `config/routes.rb` so every registered
      # plugin can mount its engine/routes onto the application router. The
      # given +mapper+ is the routing mapper (the `self` of a `routes.draw`
      # block). No-op in the community release — `registry` is empty until a
      # consumer gem registers a plugin.
      def draw_routes(mapper)
        registry.each_value do |registration|
          registration.routes_callbacks.each { |callback| callback.call(mapper) }
        end
        nil
      end

      def reset!
        @registry = nil
      end

      private

      def registry
        @registry ||= {}
      end
    end
  end
end
