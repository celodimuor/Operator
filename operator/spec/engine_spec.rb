require 'operator_helper'

RSpec.describe Operator::Engine do
  let(:routes) { Rails.application.routes.routes.to_a }
  let(:first_core_index) { routes.index { |route| route.path.spec.to_s.start_with?('/api/v1/accounts/:account_id/conversations') } }

  it 'is mounted under /operator' do
    expect(Rails.application.routes.url_helpers.operator_path).to eq('/operator')
  end

  it 'places every tombstone ahead of core routes' do
    tombstone_indexes = routes.each_index.select { |index| routes[index].requirements[:controller] == 'operator/tombstones' }

    expect(tombstone_indexes).not_to be_empty
    expect(tombstone_indexes.max).to be < first_core_index
  end

  it 'mounts the engine after core routes' do
    mount_index = routes.index { |route| route.path.spec.to_s == '/operator' }

    expect(mount_index).to be > first_core_index
  end
end
