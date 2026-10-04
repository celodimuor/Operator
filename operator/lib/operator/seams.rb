module Operator
  # The single registry of every point where Operator changes core behaviour.
  #
  # A seam prepends one small Operator module onto one core class (or its
  # singleton class). The declared signatures are the contract with upstream:
  # the guard spec named by `guard:` fails loudly when upstream renames or
  # re-shapes a method we depend on.
  module Seams
    Seam = Data.define(:target, :extension, :signatures, :singleton, :guard) do
      def target_class
        Object.const_get(target)
      end

      def extension_module
        Object.const_get(extension)
      end

      def receiver
        singleton ? target_class.singleton_class : target_class
      end

      def apply
        receiver.prepend(extension_module) unless applied?
      end

      def applied?
        receiver.ancestors.include?(extension_module)
      end

      def guard_spec_path
        Operator.root.join('spec/seams', "#{guard}_spec.rb")
      end
    end

    class << self
      def registry
        @registry ||= []
      end

      # @param target [String] core constant name, resolved lazily so core autoloading is untouched
      # @param with [String] Operator module name under Operator::Seams
      # @param signatures [Hash{Symbol=>Array}] method name => expected Method#parameters of the core method
      # @param singleton [Boolean] prepend onto the singleton class (for class-level APIs)
      # @param guard [String] basename of the spec under operator/spec/seams that verifies this seam
      def register(target, with:, signatures:, guard:, singleton: false)
        registry << Seam.new(
          target: target,
          extension: with,
          signatures: signatures.transform_values(&:freeze).freeze,
          singleton: singleton,
          guard: guard
        )
      end

      def find(target)
        registry.find { |seam| seam.target == target.to_s } ||
          raise(ArgumentError, "No seam registered for #{target}")
      end

      def apply!
        registry.each(&:apply)
      end
    end

    register 'ChatwootHub',
             with: 'Operator::Seams::ChatwootHubExt',
             singleton: true,
             guard: 'chatwoot_hub',
             signatures: {
               sync_with_hub: [],
               register_instance: [%i[req company_name], %i[req owner_name], %i[req owner_email]],
               emit_event: [%i[req event_name], %i[req event_data]]
             }
  end
end
