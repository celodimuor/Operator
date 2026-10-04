module Operator
  # Serialises the core route table (verb, path, controller#action) so a spec
  # can detect upstream route changes on every merge. Tombstones and the
  # Operator mount are excluded: they are ours, not upstream's.
  module RouteSnapshot
    PATH = Operator.root.join('spec/snapshots/core_routes.txt')

    def self.current
      Rails.application.routes.routes
           .reject { |route| operator_route?(route) }
           .map { |route| line_for(route) }
           .uniq
           .sort
    end

    def self.write(path: PATH)
      path.dirname.mkpath
      path.write("#{current.join("\n")}\n")
    end

    def self.read(path: PATH)
      path.read.split("\n")
    end

    def self.operator_route?(route)
      requirements = route.requirements
      requirements[:controller].to_s.start_with?('operator/') || mounts_engine?(route)
    end
    private_class_method :operator_route?

    def self.mounts_engine?(route)
      route.app.respond_to?(:app) && route.app.app == Operator::Engine
    end
    private_class_method :mounts_engine?

    def self.line_for(route)
      verb = route.verb.presence || 'ANY'
      action = [route.requirements[:controller], route.requirements[:action]].compact.join('#')
      "#{verb} #{route.path.spec} #{action}".strip
    end
    private_class_method :line_for
  end
end
