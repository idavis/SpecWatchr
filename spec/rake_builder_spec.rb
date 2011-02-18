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

  describe "when executing build" do
    before(:each) do
      $stdout.stub!(:puts) { }
    end

    specify "the default rake comand should be rake" do
      RakeBuilder.rake_command.should == "rake"
    end

    it "should allow rake command to be overriden" do
      RakeBuilder.rake_command = "rake other"
      RakeBuilder.rake_command.should == "rake other"
    end
  end
end
