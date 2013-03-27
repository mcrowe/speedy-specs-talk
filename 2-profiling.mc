PROFILING:

Method 1 (Ineffective):
  - Find slowest specs (e.g. rspec --profile)
  - Attack slowest specs one-by-one
  - Low return (individual specs are negligable in large suite).

Method 2 (Effective):
  - Find where *entire* suite spends most of its time
  - Profile entire suite => hot spots
  - Found a single method that takes 30% of the time of our entire suite.

```ruby
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
```