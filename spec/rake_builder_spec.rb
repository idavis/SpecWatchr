require "./watcher_dot_net.rb"

describe RakeBuilder do
  describe "when initializing dot net watcher with RakeBuilder" do
    before(:each) do
      $stdout.stub!(:puts) { }
      @builder = mock("builder")
      RakeBuilder.stub!(:new).with(".").and_return(@builder)
      @watcher = WatcherDotNet.new ".", { :builder => :RakeBuilder, :test_runner => :MSTestRunner }
    end

    it "should return RakeBuilder" do
      @watcher.builder.should == @builder
    end
  end
end
