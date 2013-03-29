# TRANSACTIONAL CLEAN-UP WITH CAPYBARA:
# (Jose Valim: http://blog.plataformatec.com.br/2011/12/three-tips-to-improve-the-performance-of-your-test-suite/)
#
# Profiler says:
#   - Database clean-up between specs is slow
#
# Clean-up:
#   - Required after every spec
#   - Transactions => FAST
#   - Truncation => SLOW
#
# Capybara:
#   - Separate thread => Separate DB connection => No Transactions!
#   - Use Truncation
#
# Solution:
#   - Force ActiveRecord to use same connection in all threads
#   - Use Transactions!
#
# Result:
#   - 10% improvement

# spec_helper.rb
#
class ActiveRecord::Base
  mattr_accessor :shared_connection
  @@shared_connection = nil

  def self.connection
    @@shared_connection || retrieve_connection
  end
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end

ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection