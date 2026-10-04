module Operator
  module Branding
    # Writes the branding values from operator/config/branding.yml into
    # InstallationConfig. Idempotent: rows already holding the value are left alone.
    class Apply
      CONFIG_PATH = Operator.root.join('config/branding.yml')

      def self.call(config_path: CONFIG_PATH)
        new(config_path: config_path).call
      end

      def initialize(config_path:)
        @config_path = config_path
      end

      def call
        values.each { |name, value| upsert(name, value) }
      end

      private

      attr_reader :config_path

      def values
        YAML.safe_load_file(config_path)
      end

      def upsert(name, value)
        config = InstallationConfig.find_or_initialize_by(name: name)
        return if config.persisted? && config.value == value

        config.value = value
        config.locked = true
        config.save!
      end
    end
  end
end
