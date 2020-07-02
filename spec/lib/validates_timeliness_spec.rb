# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Validates Timeliness threadsafety" do
  after(:each) do
    # reset to not mess up other specs
    load(Rails.root.join("config/initializers/validates_timeliness.rb"))
  end

  let(:us_date) { "06/30/2016" }
  let(:eu_date) { "30/06/2016" }

  it "doesn't need re-configuration per thread (fails with Timeliness >= 0.4 but should be fixed with ValidatesTimeliness >= 5.0.0.alpha5)" do
    # Timeliness.use_euro_formats -- in initializer
    expect(Timeliness.parse(eu_date)).not_to be_nil
    expect(Timeliness.parse(us_date)).to be_nil
    threads = []
    threads << Thread.new { expect(Timeliness.parse(eu_date)).not_to be_nil }
    threads << Thread.new { expect(Timeliness.parse(us_date)).to be_nil }
    threads.each(&:join)
  end

  it "is thread_safe (fails with Timeliness < 0.4, fixed with Timeliness >= 0.4)" do
    threads = []
    threads << Thread.new do
      Timeliness.use_euro_formats
      10_000.times { expect(Timeliness.parse(eu_date)).not_to be_nil }
    end
    threads << Thread.new do
      Timeliness.use_us_formats
      10_000.times { expect(Timeliness.parse(us_date)).not_to be_nil }
    end
    threads.each do |t|
      t.report_on_exception = false
      t.join
    end
  end
end
