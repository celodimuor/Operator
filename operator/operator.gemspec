require_relative 'lib/operator/version'

Gem::Specification.new do |spec|
  spec.name = 'operator'
  spec.version = Operator::VERSION
  spec.authors = ['HEYCH']
  spec.summary = 'Operator: multi-tenant customer operations platform built on the Chatwoot core'
  spec.homepage = 'https://github.com/celodimuor/Operator'
  spec.required_ruby_version = '>= 3.4'
  # Proprietary. The surrounding Chatwoot core is MIT; see /NOTICE.
  spec.licenses = []
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['{app,config,db,lib}/**/*', 'README.md']
  spec.require_paths = ['lib']
end
