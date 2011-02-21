require "./watcher_dot_net.rb"

describe LambSpecRunner do
  before(:each) { @test_runner = LambSpecRunner.new "." }
  it "should all for set and get of lamb_spec_path" do
    LambSpecRunner.lamb_spec_path = "c:\\lambspec.exe"
    LambSpecRunner.lamb_spec_path.should == "c:\\lambspec.exe"
  end

  it "should should resolve test command" do
    LambSpecRunner.lamb_spec_path = "lambspec.exe"
    @test_runner.test_cmd("test1.dll", "SomeTestSpec").should == '"lambspec.exe" "test1.dll" SomeTestSpec'
  end

  describe "when executing tests" do
    before(:each) do
      @sh = mock("CommandShell")
      CommandShell.stub!(:new).and_return(@sh)
      @sh.stub!(:execute).and_return("")
      @test_runner = LambSpecRunner.new "."
    end

    it "should execute tests against each dll" do
      @test_runner.test_dlls = ["./test1.dll", "./test2.dll" ]
      
      @sh.should_receive(:execute).twice()

      @test_runner.execute "SomeTestSpec"

    end
  end

  describe "output formatting" do
    before(:each) do
      @sh = mock("CommandShell")
      CommandShell.stub!(:new).and_return(@sh)
      @test_runner = LambSpecRunner.new "."
      @sh.stub!(:execute).and_return("")
      @test_runner.stub!(:test_dlls).and_return(["./test1.dll"])
    end

    it "should pass along output provided by LambSpecRunner.exe" do
      expected_output = <<-OUTPUT.gsub(/^ {8}/, '')
        when outputting
          should output
      OUTPUT

      test_output = <<-OUTPUT.gsub(/^ {8}/, '')
        when outputting
          should output
      OUTPUT

      given_output "./test1.dll", test_output

      @test_runner.execute "SomeTestSpec"
      @test_runner.test_results.should == expected_output
    end

    describe "multiple test dlls" do
      before(:each) { @test_runner.stub!(:test_dlls).and_return(["./test1.dll", "./test2.dll"]) }

      it "should aggregate test output" do
        dll_1_output = "output from dll1\n"
        dll_2_output = "output from dll2\n"
        
        given_output "./test1.dll", dll_1_output
        given_output "./test2.dll", dll_2_output

        expected_output = "output from dll1\noutput from dll2\n"
        
        @test_runner.execute "SomeTestSpec"
        @test_runner.test_results.should == expected_output
      end
    end
    
    def given_output(dll_name, output)
      @test_runner.stub!(:test_cmd)
                  .with(dll_name, "SomeTestSpec")
                  .and_return(dll_name)

      @sh.stub!(:execute).with(dll_name).and_return(output)
    end
  end
end
