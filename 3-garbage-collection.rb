# GARBAGE COLLECTION:
# (Peter Cooper: http://www.rubyinside.com/careful-cutting-to-get-faster-rspec-runs-with-rails-5207.html)
#
# Profiler says:
#   - Garbage collection is slow
#
# Solution:
#   - Stop garbage collection?
#   - Process bloats in memory if off completely
#   - Compromise
#
# Result:
#   - 40% improvement

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