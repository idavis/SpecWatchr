require "./watcher_dot_net.rb"

describe MSTestRunner do
  before(:each) { @test_runner = MSTestRunner.new "." }
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

  describe "when executing tests" do
    before(:each) do
      @sh = mock("CommandShell")
      CommandShell.stub!(:new).and_return(@sh)
      @test_runner = MSTestRunner.new "."
      @sh.stub!(:execute).and_return("")
    end

    it "should execute tests against each dll" do
      @test_runner.stub!(:test_dlls).and_return(["./test1.dll", "./test2.dll"])
      @sh.should_receive(:execute).twice()
      @test_runner.execute "SomeTestSpec"
    end

    describe "test statuses" do
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
    end

    describe "output formatting" do
      before(:each) do
        @sh = mock("CommandShell")
        CommandShell.stub!(:new).and_return(@sh)
        @test_runner = MSTestRunner.new "."
        @sh.stub!(:execute).and_return("")
        @test_runner.stub!(:test_dlls).and_return(["./test1.dll"])
      end

      context "is : \"No tests to execute\"" do
        it "should return no specs found" do
          expected_output = <<-OUTPUT.gsub(/^ {12}/, '')
            Test Inconclusive:
            No tests found under SomeTestSpec

          OUTPUT

          given_output "./test1.dll", "No tests to execute"

          @test_runner.execute "SomeTestSpec"
          @test_runner.test_results.should == expected_output
        end
      end

      context "has failing tests" do
        context "single behavioral test under spec" do
          it "should format test output with nice tabs" do
            expected_output = <<-output.gsub(/^ {14}/, '')
              Failed Tests:
              when failing test
                  it should fail first test
                  Exception occured on following line

            output

            console_output = <<-console.gsub(/^ {14}/, '')
              Failed    autotestnet.when_failing_test.it_should_fail_first_test
              [errormessage] Exception occured on following line
            console

            given_output "./test1.dll", console_output

            @test_runner.execute "SomeTestSpec"
            @test_runner.test_results.should == expected_output
          end

          it "should set first_failed_test" do
            expected_output = <<-output.gsub(/^ {14}/, '')
              Failed Tests:
              when failing test
                  it should fail first test
                  Exception occured on following line

            output

            console_output = <<-console.gsub(/^ {14}/, '')
              Failed    autotestnet.when_failing_test.it_should_fail_first_test
              [errormessage] Exception occured on following line
            console

            given_output "./test1.dll", console_output

            @test_runner.execute "SomeTestSpec"
            @test_runner.failed.should == true
            @test_runner.first_failed_test.should == expected_output 
          end

          context "multi line error message" do
            it "should include multi line error message" do
              expected_output = <<-output.gsub(/^ {16}/, '')
                Failed Tests:
                when failing test
                    it should fail first test
                      Exception occured on following line
                      line 2

                    it should fail first test2
                      Exception occured on following line
                      another lines of error
                      yet some more

              output

              console_output = <<-console.gsub(/^ {14}/, '')
                gibberish
                Failed    autotestnet.when_failing_test.it_should_fail_first_test
                [errormessage] Exception occured on following line
                line 2
                Passed    autotestnet.when_passing.it_should_pass
                Failed    autotestnet.when_failing_test.it_should_fail_first_test2
                [errormessage] Exception occured on following line
                another lines of error
                yet some more
                Passed    autotestnet.when_passing.it_should_pass
              console

              given_output "./test1.dll", console_output

              @test_runner.execute "SomeTestSpec"
              @test_runner.test_results.should == expected_output
            end
          end
        end
      end

      context "has passed tests" do
        context "single behavioral test under spec" do
          it "should format test output with nice tabs" do
            expected_output = <<-output.gsub(/^ {14}/, '')
              All Passed:
              when passing test
                  it should pass first test

                  it should pass second test
              
              2 tests ran and passed
            output

            console_output = <<-console.gsub(/^ {14}/, '')
              Passed    autotestnet.when_passing_test.it_should_pass_first_test
              Passed    autotestnet.when_passing_test.it_should_pass_second_test
            console

            given_output "./test1.dll", console_output

            @test_runner.execute "SomeTestSpec"
            @test_runner.test_results.should == expected_output
          end
        end

        context "multiple behavioral tests under spec" do
          it "should format test output with nice tabs" do
            expected_output = <<-output.gsub(/^ {14}/, '')
              All Passed:
              when passing other test
                  it should pass other test

              when passing test
                  it should pass second test

                  it should pass first test
              
              3 tests ran and passed
            output

            console_output = <<-console.gsub(/^ {14}/, '')
              Passed    autotestnet.when_passing_test.it_should_pass_first_test
              Passed    autotestnet.when_passing_test.it_should_pass_second_test
              Passed    autotestnet.when_passing_other_test.it_should_pass_other_test
            console

            given_output "./test1.dll", console_output

            @test_runner.execute "SomeTestSpec"
            @test_runner.test_results.should == expected_output
          end
        end
      end

      context "multiple dlls" do
        before { @test_runner.stub!(:test_dlls).and_return(["./test1.dll", "./test2.dll"]) }
        

        it "should only show failed test output even if another dll has all tests passed" do
          expected_output = <<-output.gsub(/^ {12}/, '')
            Failed Tests:
            when failing test
                it should fail first test

                it should fail second test

          output

          console_output_dll1 = <<-console.gsub(/^ {12}/, '')
            Passed    autotestnet.when_passing_other_test.it_should_pass_other_test
          console

          console_output_dll2 = <<-console.gsub(/^ {12}/, '')
            Failed    autotestnet.when_failing_test.it_should_fail_first_test
            Failed    autotestnet.when_failing_test.it_should_fail_second_test
          console

          given_output "./test1.dll", console_output_dll1
          given_output "./test2.dll", console_output_dll2

          @test_runner.execute "SomeTestSpec"
          @test_runner.test_results.should == expected_output
        end

        it "should aggregate output of both failing test executions" do
          expected_output = <<-output.gsub(/^ {12}/, '')
            Failed Tests:
            when failing other test
                it should fail other test

            Failed Tests:
            when failing test
                it should fail first test

                it should fail second test

          output

          console_output_dll1 = <<-console.gsub(/^ {12}/, '')
            Failed    autotestnet.when_failing_other_test.it_should_fail_other_test
          console

          console_output_dll2 = <<-console.gsub(/^ {12}/, '')
            Failed    autotestnet.when_failing_test.it_should_fail_first_test
            Failed    autotestnet.when_failing_test.it_should_fail_second_test
          console

          given_output "./test1.dll", console_output_dll1
          given_output "./test2.dll", console_output_dll2

          @test_runner.execute "SomeTestSpec"
          @test_runner.test_results.should == expected_output
        end

        it "should set first_failed_test from first executed dll" do
            expected_output = <<-output.gsub(/^ {12}/, '')
            Failed Tests:
            when failing other test
                it should fail other test

            Failed Tests:
            when failing test
                it should fail first test

                it should fail second test

          output

          console_output_dll1 = <<-console.gsub(/^ {12}/, '')
            Failed    autotestnet.when_failing_other_test.it_should_fail_other_test
          console

          console_output_dll2 = <<-console.gsub(/^ {12}/, '')
            Failed    autotestnet.when_failing_test.it_should_fail_first_test
            Failed    autotestnet.when_failing_test.it_should_fail_second_test
          console

          given_output "./test1.dll", console_output_dll1
          given_output "./test2.dll", console_output_dll2

          @test_runner.execute "SomeTestSpec"
          @test_runner.first_failed_test.should == <<-expected.gsub(/^ {12}/, '')
            Failed Tests:
            when failing other test
                it should fail other test

          expected
        end

        it "should aggregate output of both passing test executions" do
          expected_output = <<-output.gsub(/^ {12}/, '')
            All Passed:
            when passing other test
                it should pass other test

            All Passed:
            when passing test
                it should pass first test

                it should pass second test
            
            3 tests ran and passed
          output

          console_output_dll1 = <<-console.gsub(/^ {12}/, '')
            Passed    autotestnet.when_passing_other_test.it_should_pass_other_test
          console

          console_output_dll2 = <<-console.gsub(/^ {12}/, '')
            Passed    autotestnet.when_passing_test.it_should_pass_first_test
            Passed    autotestnet.when_passing_test.it_should_pass_second_test
          console

          given_output "./test1.dll", console_output_dll1
          given_output "./test2.dll", console_output_dll2

          @test_runner.execute "SomeTestSpec"
          @test_runner.test_results.should == expected_output
        end

        it "should summarize number of passed tests on last line" do
          expected_output = "3 tests ran and passed"

          console_output_dll1 = <<-console.gsub(/^ {12}/, '')
            Passed    autotestnet.when_passing_other_test.it_should_pass_other_test
          console

          console_output_dll2 = <<-console.gsub(/^ {12}/, '')
            Passed    autotestnet.when_passing_test.it_should_pass_first_test
            Passed    autotestnet.when_passing_test.it_should_pass_second_test
          console

          given_output "./test1.dll", console_output_dll1
          given_output "./test2.dll", console_output_dll2

          @test_runner.execute "SomeTestSpec"
          @test_runner.test_results.split("\n").last.should == expected_output
        end

        it "should aggregate output of both inconclusive test executions" do
            expected_output = <<-output.gsub(/^ {14}/, '')
              Test Inconclusive:
              No tests found under SomeTestSpec

              Test Inconclusive:
              No tests found under SomeTestSpec

            output

            given_output "./test1.dll", "No tests to execute" 
            given_output "./test2.dll", "No tests to execute"

            @test_runner.execute "SomeTestSpec"
            @test_runner.test_results.should == expected_output
        end
      end
    end
    
    def given_output(dll_name, output)
      @test_runner.stub!(:test_cmd).with(dll_name, "SomeTestSpec").and_return(dll_name)
      @sh.stub!(:execute).with(dll_name).and_return(output)
    end
  end
end
