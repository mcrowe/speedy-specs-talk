# WHITELISTED OBSERVERS:
# (Pat Maddox: no_peeping_toms)
#
# Profiler says:
#   - Observers take a *lot* of time
#
# Observers:
#   - Usually "asides" (not part of primary business logic)
#   - Often expensive
#   - e.g. Create a user => send emails, create background jobs, etc.
#
# Solution:
#   - Disable observers by default
#   - Whitelist observers as needed
#
# Result:
#   - 10% improvement

# Gemfile
#
group :test do
  gem 'no_peeping_toms'
end

# spec_helper.rb
#
RSpec.configure do |config|

  config.before(:suite) do
    ActiveRecord::Observer.disable_observers
  end

end

# some_spec.rb
#
it 'has observers' do
  ActiveRecord::Observer.with_observers(:user_observer) do
    # UserObserver enabled...
  end
end