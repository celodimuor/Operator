require 'operator/route_snapshot'

namespace :operator do
  namespace :routes do
    desc 'Refresh the reviewed snapshot of the core route table (operator/spec/snapshots/core_routes.txt)'
    task snapshot: :environment do
      Operator::RouteSnapshot.write
      puts "wrote #{Operator::RouteSnapshot::PATH} (#{Operator::RouteSnapshot.current.size} routes)"
    end
  end
end
