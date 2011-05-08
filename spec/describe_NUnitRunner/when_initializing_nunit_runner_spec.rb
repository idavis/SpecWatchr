require "./watcher_dot_net.rb"

describe NUnitRunner do
  before(:each) do
    @test_runner = NUnitRunner.new "." 
    $stdout.stub!(:puts) { }
  end
  
  context "initializing NUnitRunner" do
    it "should default ms test runner exe to be the 64bit installation location" do
      NUnitRunner.nunit_path.should == "C:\\program files (x86)\\nunit 2.5.9\\bin\\net-2.0\\nunit-console-x86.exe"
    end
  end

  it "should resolve test command based on spec name" do
    NUnitRunner.nunit_path = "nunit.exe"
    @test_runner.test_cmd("test1.dll", "SomeTestSpec").should == "\"nunit.exe\" \"test1.dll\" /nologo /labels /include=SomeTest"

    @test_runner.test_cmd("test1.dll", "SomeTestspec").should == "\"nunit.exe\" \"test1.dll\" /nologo /labels /include=SomeTest"
  end

  it "should resolve test command based on spec name starting with describe" do
    NUnitRunner.nunit_path = "nunit.exe"
    @test_runner.test_cmd("test1.dll", "describe_SomeTest").should == "\"nunit.exe\" \"test1.dll\" /nologo /labels /include=SomeTest"

    @test_runner.test_cmd("test1.dll", "describe_SomeTest").should == "\"nunit.exe\" \"test1.dll\" /nologo /labels /include=SomeTest"
  end
end
