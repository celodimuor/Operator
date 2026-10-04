namespace :operator do
  namespace :branding do
    desc 'Apply operator/config/branding.yml to InstallationConfig'
    task apply: :environment do
      Operator::Branding::Apply.call
    end
  end
end

# Branding must be in place on every deploy; `db:migrate` is the release step.
Rake::Task['db:migrate'].enhance do
  Rake::Task['operator:branding:apply'].invoke if ActiveRecord::Base.connection.table_exists?('installation_configs')
end
