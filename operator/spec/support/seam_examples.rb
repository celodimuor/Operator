# Shared contract for every seam guard spec. It proves three things against
# the live classes: the Operator module sits ahead of the core class, every
# method we override still exists in core, and its signature is unchanged.
RSpec.shared_examples 'an applied seam' do |target|
  let(:seam) { Operator::Seams.find(target) }

  it 'is applied ahead of the core implementation' do
    ancestors = seam.receiver.ancestors
    expect(ancestors.index(seam.extension_module)).to be < ancestors.index(seam.receiver)
  end

  it 'overrides only methods that core still defines, with unchanged signatures' do
    seam.signatures.each do |method_name, parameters|
      core_method = seam.extension_module.instance_method(method_name).super_method
      expect(core_method).not_to be_nil, "core no longer defines #{target}.#{method_name}"
      expect(core_method.parameters).to eq(parameters), "core changed the signature of #{target}.#{method_name}"
    end
  end

  it 'has a guard spec next to this one' do
    expect(seam.guard_spec_path).to exist
  end
end
