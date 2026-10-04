require 'operator_helper'

RSpec.describe 'Seam: ChatwootHub' do
  include_examples 'an applied seam', 'ChatwootHub'

  it 'does not call home when the version check syncs' do
    expect(ChatwootHub.sync_with_hub).to eq({})
    expect(a_request(:any, /hub\.2\.chatwoot\.com/)).not_to have_been_made
  end

  it 'keeps the version-check job safe with an empty payload' do
    expect { Internal::CheckNewVersionsJob.new.send(:update_version_info) }.not_to raise_error
  end

  it 'ignores instance registration and events' do
    expect(ChatwootHub.register_instance('HEYCH', 'Owner', 'owner@example.com')).to be_nil
    expect(ChatwootHub.emit_event('ignored', {})).to be_nil
    expect(a_request(:any, /hub\.2\.chatwoot\.com/)).not_to have_been_made
  end
end
