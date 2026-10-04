require 'operator_helper'

RSpec.describe 'Tombstone routes for removed enterprise endpoints', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:headers) { admin.create_new_auth_token }

  shared_examples 'a tombstoned path' do |path|
    it "answers 404 for #{path}" do
      get "/api/v1/accounts/#{account.id}/#{path}", headers: headers

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq('error' => 'not_available')
    end
  end

  include_examples 'a tombstoned path', 'sla_policies'
  include_examples 'a tombstoned path', 'sla_policies/1'
  include_examples 'a tombstoned path', 'custom_roles'
  include_examples 'a tombstoned path', 'audit_logs'
  include_examples 'a tombstoned path', 'saml_settings'
  include_examples 'a tombstoned path', 'agent_capacity_policies/1/users'
  include_examples 'a tombstoned path', 'applied_slas/metrics'
  include_examples 'a tombstoned path', 'captain/assistants'
  include_examples 'a tombstoned path', 'captain/copilot_threads/1/copilot_messages'

  it 'answers 404 for the SAML login trigger' do
    post '/api/v1/auth/saml_login', params: { email: 'someone@example.com' }

    expect(response).to have_http_status(:not_found)
  end

  it 'answers 404 for the custom-domain challenge' do
    get '/.well-known/cf-custom-hostname-challenge/abc'

    expect(response).to have_http_status(:not_found)
  end

  it 'leaves the MIT captain endpoints to core' do
    get "/api/v1/accounts/#{account.id}/captain/preferences", headers: headers

    expect(response).not_to have_http_status(:not_found)
  end
end
