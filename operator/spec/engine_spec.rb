require 'operator_helper'

RSpec.describe Operator::Engine do
  it 'is mounted under /operator' do
    expect(Rails.application.routes.url_helpers.operator_path).to eq('/operator')
  end

  it 'keeps core routes ahead of Operator routes except for tombstones' do
    paths = Rails.application.routes.routes.map { |route| route.path.spec.to_s }
    first_core = paths.index { |path| path.start_with?('/api/v1/accounts/:account_id/conversations') }
    last_tombstone = paths.rindex { |path| path.include?('cf-custom-hostname-challenge') }
    mount_index = paths.index('/operator')

    expect(last_tombstone).to be < first_core
    expect(mount_index).to be > first_core
  end
end
