require 'operator/seams'
require 'operator/tombstone_routes'

module Operator
  class Engine < ::Rails::Engine
    isolate_namespace Operator

    initializer 'operator.routes' do |app|
      app.routes.prepend { Operator::TombstoneRoutes.draw(self) }
      app.routes.append { mount Operator::Engine, at: '/operator', as: :operator }
    end

    config.to_prepare do
      Operator::Seams.apply!
    end
  end
end
