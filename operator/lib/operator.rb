require 'operator/version'
require 'operator/engine'

# Operator extends the Chatwoot core as an isolated Rails engine.
# Core behaviour is only ever changed through Operator::Seams.
module Operator
  def self.root
    Engine.root
  end
end
