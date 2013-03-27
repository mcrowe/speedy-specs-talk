# PLAN:
# Split into separate files / tabs
# Put in MC format s.t. can document w/o comments, and use "ruby" blocks for code.
# Show in distraction-free mode.


Unbounce's spec suite: ~ 3000 specs
Brought from 17+minutes -> 1.5 minutes (though its now creeping back up over past 6 mos)

Assuming you don't want to refactor system.
Yes isolating db is good, and fast, but not always practical.

Right solution:
  Lots of attention these days, but usually assume you have the luxury of starting from scratch
  or spending a few months refactoring
  - isolate from db (e.g separate business objects as POROs and test those)
  - isolate from other objects (add a bunch of stubbing / mocking)

  Problem: Inherit legacy code base, legacy spec suite (legacy = 2 years...)
  Yes, could probably have gotten down to a few seconds, but at huge dev cost.
  Want to do 20% of work to get 80% of result.

What didn't work:
  isolating db: too much refactoring
  in memory db: locked in to mysql
  rspec --profile (list slow specs and attack): Not dominant problem
  spork



########################################
# 1. Profiling
########################################

# BAD
# What individual specs are slow? I'll speed up the slowest.
# - > rspec --profile
# - Get list of slow specs
# - Attack slow specs individually
#
# Low return. Individual specs are negligable in suite of 3000 specs.

# GOOD
# Where does my entire spec suite spend most of its time?
#
# We found a single method that takes 30% of the time of our entire suite.
# It is slow, AND, gets called in many specs.
#

# Gemfile
#
group :test do
  gem 'ruby-prof'
end

# spec_helper.rb
#
require 'ruby-prof'

RSpec.configure do |config|

  config.before(:suite) do
    RubyProf.start
  end

  config.after(:suite) do
    profile = RubyProf.stop
    RubyProf::GraphHtmlPrinter.new(
      File.open('profile.html', 'w')
    ).print
  end

end


##################################
# 2. Manual Garbage collection
##################################

#
# Credit: Peter Cooper, http://www.rubyinside.com/careful-cutting-to-get-faster-rspec-runs-with-rails-5207.html
#
# Bloating if totally off, find a compromise b/w speed and high memory usage.
#
# TODO: Measure the improvement you got and put it here.

# garbage_sweeper.rb
#
class GarbageSweeper

  SWEEP_INTERVAL = 9

  def initialize
    @count = 0
  end

  def sweep
    collect_garbage if @count % SWEEP_INTERVAL == 0
    @count += 1
  end

  private

    def collect_garbage
      GC.enable
      GC.start
      GC.disable
    end

end

# spec_helper.rb
#
garbage_sweeper = GarbageSweeper.new

RSpec.configure do |config|

  config.after(:each) do
    garbage_sweeper.sweep
  end

end

##################################
# 3. Opt-in Observers
##################################

# Observers => usually "asides", not part of the regular business logic.
# e.g. Create a new user => emails sent, create a bunch of bg jobs, etc., etc.
#
# Therefore, disable observers by default and only enable them when you are actually testing them.
#
# Credit: Pat Maddox, no_peeping_toms
#
# TODO: Measure improvement

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

########################################
# 4. Transactional Cleanup w/ Capybara
########################################

# Need cleanup after every spec.
# Transactions => Very fast
# Truncation => Slow
#
# Capybara requires Truncation out of the box
#
# Transactions cleanup *much* faster than Truncation.
# Capybara => Separate thread => Separate db connection => Transactions don't work.
#
# Popular solution: Use truncation (with DatabaseCleaner)
#
# Faster: Force ActiveRecord to use same connection in all threads, and use Transactions
#
# Credit: Jose Valim, http://blog.plataformatec.com.br/2011/12/three-tips-to-improve-the-performance-of-your-test-suite/
#
# TODO: Measure performance difference

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

########################################
# 5. Fixtures
########################################

# Factories are flexible
# Fixtures are FAST
# => Create data once, rollback changes with transactions

# Still want to use factories everywhere for flexibility.
#
# Profiling => Creating same records again and again and again through good number of specs
# e.g. Roles, SubscriptionPlans, ...
#
# Only need to create these once!
#
# TODO: Performance measurement

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
    load 'request_spec/seeds.rb'
  end

end
