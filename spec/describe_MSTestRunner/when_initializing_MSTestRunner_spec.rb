require "./watcher_dot_net.rb"

describe MSTestRunner do
  before(:each) do 
    @test_runner = MSTestRunner.new "." 
    $stdout.stub!(:puts) { }
  end
  
  context "initializing MSTestRunner" do
    it "should default ms test runner exe to be the 64bit installation location" do
      MSTestRunner.ms_test_path.should == "C:\\program files (x86)\\microsoft visual studio 10.0\\common7\\ide\\mstest.exe"
    end
  end

  describe "finding test_config" do
    it "should find test config file named Local.testsettings" do
      given_test_config "./Local.testsettings"
      @test_runner.test_config.should == "Local.testsettings"
    end

    it "should find test config file named LocalTestRun.testrunconfig" do
      given_test_config "./LocalTestRun.testrunconfig"
      @test_runner.test_config.should == "LocalTestRun.testrunconfig"
    end

    def given_test_config file_name
      Find.stub!(:find).with(".").and_yield(file_name)
    end
  end
end
