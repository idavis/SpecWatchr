require "./watcher_dot_net.rb"

describe WatcherDotNet do
  before(:each) { $stdout.stub!(:puts) { } }

  describe "when initializing dot net watchr" do
    context "finding builder" do
      [
        { :builder => :MSBuilder },
        { :builder => :RakeBuilder }
      ].each do |kvp|
        it "should find #{kvp[:builder].to_s}" do
          @watcher = WatcherDotNet.new ".", 
            { :builder => kvp[:builder], :test_runner => :MSTestRunner }
          @watcher.builder.class.to_s.should == kvp[:builder].to_s
        end
      end
    end

    context "finding test runner" do
      before(:each) do
        mock = mock("Builder")
        mock.stub!(:new)
      end

      [
        { :test_runner => :MSTestRunner },
        { :test_runner => :NUnitRunner },
        { :test_runner => :NSpecRunner }
      ].each do |kvp|
        it "should find #{kvp[:test_runner].to_s}" do
          @watcher = 
            WatcherDotNet.new ".", { :builder => :MSBuilder, :test_runner => kvp[:test_runner] }

          @watcher.test_runner.class.to_s.should == kvp[:test_runner].to_s
        end
      end
    end

    context "public accessors" do
      before(:each) do
        @builder = mock("builder")
        MSBuilder.stub!(:new).and_return(@builder)
        @builder.stub!(:failed).and_return(true)

        @notifier = mock("notifier")
        GrowlNotifier.stub!(:new).and_return(@notifier)
        @notifier.stub!(:execute)

        @test_runner = mock("test_runner")
        MSTestRunner.stub!(:new).and_return(@test_runner)
        @test_runner.stub!(:inconclusive).and_return(false)
        @test_runner.stub!(:failed).and_return(false)
        @test_runner.stub!(:usage).and_return("usage")

        @command_shell = mock("command_shell")
        CommandShell.stub!(:new).and_return(@command_shell)

        @watcher = WatcherDotNet.new ".", { :builder => :MSBuilder, :test_runner => :MSTestRunner }
      end

      it "should expose test runner" do
        @watcher.test_runner.should == @test_runner
      end

      it "should expose notifier" do
        @watcher.notifier.should == @notifier
      end

      it "should expose builder" do
        @watcher.builder.should == @builder
      end

      it "should expose sh" do
        @watcher.sh.should == @command_shell
      end
    end
  end
end

