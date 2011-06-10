require "./watcher_dot_net.rb"

describe WatcherDotNet do
  before(:each) { $stdout.stub!(:puts) { } }

  context "discovery of usage" do
    before(:each) do
        @builder = mock("builder")
        MSBuilder.stub!(:new).and_return(@builder)
        @builder.stub!(:failed).and_return(false)
        @builder.stub!(:execute)

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
        @test_runner.stub!(:test_dlls).and_return(["test1.dll"])
        @test_runner.stub!(:execute).with("")
        @test_runner.stub!(:test_results).and_return("")
        @test_runner.stub!(:find).with("Person.cs").and_return("")

        @watcher = WatcherDotNet.new ".", { :builder => :MSBuilder, :test_runner => :MSTestRunner }
    end

      context "no test dlls found" do
        before(:each) { @test_runner.stub!(:test_dlls).and_return([]) }

        it "should growl if not test dlls are found" do
          @notifier.should_receive(:execute).with("discovery", "specwatchr didn't find any test dll's. specwatchr looks for a .csproj that ends in Test, Tests, Spec, or Specs.  If you do have that, stop specwatchr, rebuild your solution and start specwatchr back up. If you want to explicitly specify the test dll's, you can do so via dotnet.watchr.rb.", "red")
          @watcher.consider "Person.cs"
        end
      end

      context "sln directory and csproj directory at same level" do
        before(:each) { Dir.stub!(:entries).with(".").and_return(["SomeProject.sln", "SomeProject.csproj"]) }

        it "should not growl specwatchr configuration" do
          @notifier.should_not_receive(:execute).with("specwatchr", "builder: #{@watcher.builder.class}\ntest runner: #{@watcher.test_runner.class}\nconfig file: dotnet.watchr.rb", "green")

          @watcher.first_run = true

          @watcher.consider "Person.cs"
        end
        
        it "should return true for unsupported_solution_structure?" do
          @watcher.unsupported_solution_structure?.should == true
        end

        it "should not build" do
          @builder.should_not_receive(:execute)

          @watcher.consider "Person.cs"
        end

        it "should growl that folder structure is unsupported" do
          message = "The solution structure you have is unsupported by specwatchr.  CS Projects need to be in their own directories (as opposed to .csproj's existing at the same level as the .sln file).  If this is a new project, go back and recreate it...but this time make sure that the \"Create directory for solution\" check box is checked."

          @notifier.should_receive(:execute).with("specwatchr", message, "red")

          @watcher.consider "Person.cs"
        end
      end

      context "sln directory and csproj directory are not at the same level" do
        before(:each) { Dir.stub!(:entries).with(".").and_return(["SomeProject.sln"]) }

        
        it "should return true for unsupported_solution_structure?" do
          @watcher.unsupported_solution_structure?.should == false 
        end

      end

      it "should growl configuration if first run" do
        @notifier.should_receive(:execute).with("specwatchr", "builder: #{@watcher.builder.class}\ntest runner: #{@watcher.test_runner.class}\nconfig file: dotnet.watchr.rb", "green")

        @watcher.first_run = true

        @watcher.consider "Person.cs"
      end

      it "should set first_run to false after growling" do
        @watcher.first_run = true
        @watcher.consider "Person.cs"
        @watcher.first_run.should == false
      end
  end
end
