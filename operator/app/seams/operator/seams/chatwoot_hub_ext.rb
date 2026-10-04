module Operator
  module Seams
    # Keeps the installation off Chatwoot's hub: no telemetry, no registration,
    # no event emission. Push delivery is not touched because core already
    # sends directly to FCM when ENABLE_PUSH_RELAY_SERVER is false.
    module ChatwootHubExt
      def sync_with_hub
        {}
      end

      def register_instance(*)
        nil
      end

      def emit_event(*)
        nil
      end
    end
  end
end
