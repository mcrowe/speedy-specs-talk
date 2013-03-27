1. Profiling:

BAD
What individual specs are slow? I'll speed up the slowest.
- > rspec --profile
- Get list of slow specs
- Attack slow specs individually

Low return. Individual specs are negligable in suite of 3000 specs.

GOOD
Where does my entire spec suite spend most of its time?

We found a single method that takes 30% of the time of our entire suite.
It is slow, AND, gets called in many specs.


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