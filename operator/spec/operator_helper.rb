# Entry point for every Operator spec. Builds on the core rails_helper and
# turns the test environment into a real one: real Redis (OT-005), real
# network to providers only where a spec opts in, nothing doubled.
ENV['RAILS_ENV'] ||= 'test'
ENV['OPERATOR_REAL_REDIS'] ||= '1'

require_relative '../../spec/rails_helper'

Dir[File.expand_path('support/**/*.rb', __dir__)].each { |file| require file }

RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{/operator/spec/}) do |metadata|
    metadata[:operator] = true
  end
end
