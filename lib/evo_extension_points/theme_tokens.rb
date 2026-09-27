# frozen_string_literal: true

module EvoExtensionPoints
  # Theme tokens extension point. Community default: the canonical Evolution
  # palette and typography tokens. Token keys mirror the public CSS variable
  # contract declared in EXTENSION_POINTS.md of the React frontend
  # (story 0.3); keep both in sync.
  module ThemeTokens
    DEFAULT_TOKENS = {
      '--evo-color-primary-500' => '#5b4b94',
      '--evo-color-primary-foreground' => '#ffffff',
      '--evo-color-accent-500' => '#c6f135',
      '--evo-color-background' => '#211c34',
      '--evo-color-foreground' => '#f7f6f3',
      '--evo-font-sans' => 'Inter, system-ui, sans-serif'
    }.freeze

    DEFAULT_IMPL = ->(_scope) { DEFAULT_TOKENS.dup }

    class << self
      def defaults(scope: :default)
        impl = EvoExtensionPoints.impl_for(:theme_tokens) || DEFAULT_IMPL
        impl.call(scope)
      end
    end
  end
end
