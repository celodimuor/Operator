require 'operator_helper'

# Clean-room policy (ADR-0003): the enterprise tree is gone and nothing under
# operator/ refers to it. Documentation may name the directory when it
# explains the policy, so it is excluded from the reference scan.
RSpec.describe 'Clean room' do
  # Assembled from parts so this file does not match its own pattern.
  let(:forbidden_reference) { /\b#{"Enter#{'prise'}"}::|\b#{"enter#{'prise'}"}\// }
  let(:scanned_files) do
    Dir[Operator.root.join('**/*.{rb,rake,erb,yml,yaml,js,ts,vue,json}')]
      .reject { |path| path.include?('/docs/') }
  end

  it 'has no enterprise directory in the tree' do
    expect(Rails.root.join('enterprise')).not_to exist
    expect(Rails.root.join('spec/enterprise')).not_to exist
  end

  it 'defines no Enterprise constant at boot' do
    expect(Object.const_defined?(:Enterprise)).to be(false)
  end

  it 'never references enterprise code from operator/' do
    offenders = scanned_files.select { |path| File.read(path).match?(forbidden_reference) }
    expect(offenders).to be_empty
  end
end
