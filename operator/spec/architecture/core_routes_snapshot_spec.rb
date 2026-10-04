require 'operator_helper'
require 'operator/route_snapshot'

# Route guard (ADR-0005): any change to the core route table must be reviewed
# against the tombstone list. Refresh with `bundle exec rake operator:routes:snapshot`.
RSpec.describe 'Core route snapshot' do
  it 'matches the reviewed snapshot' do
    expect(Operator::RouteSnapshot::PATH).to exist, 'run `bundle exec rake operator:routes:snapshot` once and commit the file'

    added = Operator::RouteSnapshot.current - Operator::RouteSnapshot.read
    removed = Operator::RouteSnapshot.read - Operator::RouteSnapshot.current

    expect(added).to be_empty, "core routes added since the snapshot:\n#{added.join("\n")}"
    expect(removed).to be_empty, "core routes removed since the snapshot:\n#{removed.join("\n")}"
  end
end
