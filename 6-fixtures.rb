# FIXTURES:
#
# Profiler says:
#   - Creating same records again and again and again
#     (e.g. Roles, SubscriptionPlans)
#
# Creating records for specs:
#   - Factories => flexible
#   - Fixtures => FAST
#     - Create data once
#     - Rollback changes with transactions
#
# Solution:
#   - Fixtures and transactional cleanup for common data
#   - Factories for test-specific data
#
# Result:
#   - 40% improvement

# spec/seeds.rb
#
Role.populate
SystemSubscriptionPlan.populate

# spec_helper.rb
#
RSpec.configure do |config|

  # Run every example within a transaction.
  config.use_transactional_fixtures = true

  config.before(:suite) do
    # Ensure the database is clean before we run any specs.
    DatabaseCleaner.clean_with(:truncation)

    # Load spec seeds only once per run.
    load 'spec/seeds.rb'
  end

end