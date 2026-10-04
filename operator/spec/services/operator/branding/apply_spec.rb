require 'operator_helper'

RSpec.describe Operator::Branding::Apply do
  it 'writes every branding value as a locked installation config' do
    described_class.call

    %w[INSTALLATION_NAME BRAND_NAME].each do |name|
      config = InstallationConfig.find_by!(name: name)
      expect(config.value).to eq('Operator')
      expect(config).to be_locked
    end
  end

  it 'is idempotent' do
    described_class.call
    before = InstallationConfig.where(name: %w[INSTALLATION_NAME BRAND_NAME]).pluck(:updated_at)

    described_class.call

    expect(InstallationConfig.where(name: %w[INSTALLATION_NAME BRAND_NAME]).pluck(:updated_at)).to eq(before)
  end

  it 'makes the installation custom-branded so account feature flags gate the UI' do
    described_class.call

    expect(GlobalConfig.get('INSTALLATION_NAME')['INSTALLATION_NAME']).to eq('Operator')
  end
end
