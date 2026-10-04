require 'operator_helper'

RSpec.describe Operator::Seams do
  it 'applies every registered seam at boot' do
    expect(described_class.registry).to all(be_applied)
  end

  it 'has a guard spec for every seam' do
    missing = described_class.registry.reject { |seam| seam.guard_spec_path.exist? }
    expect(missing.map(&:target)).to be_empty
  end

  it 'keeps every seam module small enough to only delegate' do
    described_class.registry.each do |seam|
      path = Operator.root.join('app/seams', "#{seam.extension.underscore}.rb")
      expect(File.readlines(path).count).to be <= 30, "#{seam.extension} exceeds the 30-line seam budget"
    end
  end
end
