require "./watcher_dot_net.rb"

describe MSTestRunner do
  before(:each) do 
    @sh = mock("CommandShell")
    @sh.stub!(:execute).and_return("")
    CommandShell.stub!(:new).and_return(@sh)
    @test_runner = MSTestRunner.new "." 
    $stdout.stub!(:puts) { }
  end

  describe "when executing tests (test statuses)" do
    context "one test dll" do
      before(:each) { @test_runner.stub!(:test_dlls).and_return(["./test1.dll"]) }
      
      context "given output is: No tests to execute" do
        it "should mark test run as inconclusive" do
          given_output "./test1.dll", "No tests to execute"

          @test_runner.execute "SomeTestSpec"
          @test_runner.inconclusive.should == true
        end
      end

      context "given output contains failing tests" do
        it "should mark test run as failed" do
          given_output "./test1.dll", "Failed    SomeTest.when_testing.should_fail"

          @test_runner.execute "SomeTestSpec"
          @test_runner.failed.should == true
        end
      end

      context "given output contains no failing tests" do
        it "should mark test run as passed" do
          given_output "./test1.dll", "Passed    SomeTest.when_testing.should_pass"

          @test_runner.execute "SomeTestSpec"
          @test_runner.failed.should == false
          @test_runner.inconclusive.should == false
        end
      end
    end 

    context "multiple tests dlls" do
      before(:each) { @test_runner.stub!(:test_dlls).and_return(["./test1.dll", "./test2.dll"]) }

      it "should execute tests against each dll" do
        @sh.should_receive(:execute).twice()
        @test_runner.execute "SomeTestSpec"
      end

      context "given output is: \"No tests to execute\" for both executions" do
        it "should mark test run as inconclusive" do
          given_output "./test1.dll", "No tests to execute"
          given_output "./test2.dll", "No tests to execute"
          
          @test_runner.execute "SomeTestSpec"
          @test_runner.inconclusive.should == true
        end
      end

      context "given failures exist for at least on dll" do
        it "should mark test run as failed" do
          given_output "./test1.dll", "Failed    when_testing.should_fail"
          given_output "./test2.dll", "No tests to execute"

          @test_runner.execute "SomeTestSpec"
          @test_runner.failed.should == true
        end
      end

      context "given a test suite ran with no failures" do
        it "should mark test run as passed" do
          given_output "./test1.dll", "Passed    when_testing.should_pass"
          given_output "./test2.dll", "Passed    when_testing.should_pass_1"
          
          @test_runner.execute "SomeTestSpec"
          @test_runner.failed.should == false
          @test_runner.inconclusive.should == false
        end

        it "should ignore inconclusive runs and pass" do
          given_output "./test1.dll", "Passed    when_testing.should_pass"
          given_output "./test2.dll", "No tests to execute"
          
          @test_runner.execute "SomeTestSpec"
          @test_runner.failed.should == false
          @test_runner.inconclusive.should == false
        end
      end
    end

    def given_output(dll_name, output)
      @test_runner.stub!(:test_cmd).with(dll_name, "SomeTestSpec").and_return(dll_name)
      @sh.stub!(:execute).with(dll_name).and_return(output)
    end
  end
end
