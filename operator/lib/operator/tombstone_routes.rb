module Operator
  # Core `config/routes.rb` still declares routes for controllers that only
  # existed in the removed enterprise tree. Without these tombstones those
  # paths raise at request time; with them they answer a clean 404.
  # This is the one place Operator routes run ahead of core routes (ADR-0005).
  module TombstoneRoutes
    ACCOUNT_SCOPE = 'api/v1/accounts/:account_id'.freeze

    # Core keeps `captain/preferences` and `captain/tasks` in the MIT tree.
    CAPTAIN_CORE_PATHS = /\A(?!preferences\b|tasks\b).*/

    ACCOUNT_PATHS = %w[
      saml_settings
      audit_logs
      sla_policies
      custom_roles
      agent_capacity_policies
      applied_slas
    ].freeze

    GLOBAL_PATHS = %w[
      api/v1/auth/saml_login
      .well-known/cf-custom-hostname-challenge/:id
    ].freeze

    def self.draw(mapper)
      target = { to: 'operator/tombstones#show', via: :all }

      mapper.match "#{ACCOUNT_SCOPE}/captain/*path", constraints: { path: CAPTAIN_CORE_PATHS }, **target
      ACCOUNT_PATHS.each do |path|
        mapper.match "#{ACCOUNT_SCOPE}/#{path}", **target
        mapper.match "#{ACCOUNT_SCOPE}/#{path}/*rest", **target
      end
      GLOBAL_PATHS.each { |path| mapper.match path, **target }
    end
  end
end
