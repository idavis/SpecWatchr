require "./watcher_dot_net.rb"

describe MSTestRunner do
  before(:each) do 
    @sh = mock("CommandShell")
    CommandShell.stub!(:new).and_return(@sh)
    @test_runner = MSTestRunner.new "." 
    $stdout.stub!(:puts) { }
    @sh.stub!(:execute).and_return("")
    @test_runner.stub!(:test_dlls).and_return(["./test1.dll"])
  end

  describe "output formatting" do
    context "is : \"No tests to execute\"" do
      it "should return no specs found" do
        expected_output = <<-OUTPUT.gsub(/^ {10}/, '')
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
        it "should format test output with a little clean up" do
          expected_output = <<-output.gsub(/^ {12}/, '')
            Failed Tests:
            autotestnet.when_failing_test.it_should_fail_first_test
            Exception occured on following line

          output

          console_output = <<-console.gsub(/^ {12}/, '')
            Failed    autotestnet.when_failing_test.it_should_fail_first_test
            [errormessage] Exception occured on following line
          console

          given_output "./test1.dll", console_output

          @test_runner.execute "SomeTestSpec"
          @test_runner.test_results.should == expected_output
        end

        it "should set first_failed_test" do
          expected_output = <<-output.gsub(/^ {12}/, '')
            Failed Tests:
            autotestnet.when_failing_test.it_should_fail_first_test
            Exception occured on following line
          output

          console_output = <<-console.gsub(/^ {12}/, '')
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
            expected_output = <<-output.gsub(/^ {14}/, '')
              Failed Tests:
              autotestnet.when_failing_test.it_should_fail_first_test
              Exception occured on following line
              line 2

              autotestnet.when_failing_test.it_should_fail_first_test2
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
        it "should format test output with a little cleanup" do
          expected_output = <<-output.gsub(/^ {12}/, '')
            All Passed:
            autotestnet.when_passing_test.it_should_pass_first_test

            autotestnet.when_passing_test.it_should_pass_second_test

            2 tests ran and passed
          output

          console_output = <<-console.gsub(/^ {12}/, '')
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
          expected_output = <<-output.gsub(/^ {12}/, '')
            All Passed:
            autotestnet.when_passing_test.it_should_pass_first_test

            autotestnet.when_passing_test.it_should_pass_second_test

            autotestnet.when_passing_other_test.it_should_pass_other_test

            3 tests ran and passed
          output

          console_output = <<-console.gsub(/^ {12}/, '')
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
        expected_output = <<-output.gsub(/^ {10}/, '')
          Failed Tests:
          autotestnet.when_failing_test.it_should_fail_first_test

          autotestnet.when_failing_test.it_should_fail_second_test

        output

        console_output_dll1 = <<-console.gsub(/^ {10}/, '')
          Passed    autotestnet.when_passing_other_test.it_should_pass_other_test
        console

        console_output_dll2 = <<-console.gsub(/^ {10}/, '')
          Failed    autotestnet.when_failing_test.it_should_fail_first_test
          Failed    autotestnet.when_failing_test.it_should_fail_second_test
        console

        given_output "./test1.dll", console_output_dll1
        given_output "./test2.dll", console_output_dll2

        @test_runner.execute "SomeTestSpec"
        @test_runner.test_results.should == expected_output
      end

      it "should aggregate output of both failing test executions" do
        expected_output = <<-output.gsub(/^ {10}/, '')
          Failed Tests:
          autotestnet.when_failing_other_test.it_should_fail_other_test

          Failed Tests:
          autotestnet.when_failing_test.it_should_fail_first_test

          autotestnet.when_failing_test.it_should_fail_second_test

        output

        console_output_dll1 = <<-console.gsub(/^ {10}/, '')
          Failed    autotestnet.when_failing_other_test.it_should_fail_other_test
        console

        console_output_dll2 = <<-console.gsub(/^ {10}/, '')
          Failed    autotestnet.when_failing_test.it_should_fail_first_test
          Failed    autotestnet.when_failing_test.it_should_fail_second_test
        console

        given_output "./test1.dll", console_output_dll1
        given_output "./test2.dll", console_output_dll2

        @test_runner.execute "SomeTestSpec"
        @test_runner.test_results.should == expected_output
      end

      it "should set first_failed_test from first executed dll" do
        expected_output = <<-output.gsub(/^ {10}/, '')
          Failed Tests:
          autotestnet.when_failing_other_test.it_should_fail_other_test
          Exception occured on following line

          Failed Tests:
          autotestnet.when_failing_test.it_should_fail_first_test

          autotestnet.when_failing_test.it_should_fail_second_test

        output

        console_output_dll1 = <<-console.gsub(/^ {10}/, '')
          Failed    autotestnet.when_failing_other_test.it_should_fail_other_test
          [errormessage] Exception occured on following line
        console

        console_output_dll2 = <<-console.gsub(/^ {10}/, '')
          Failed    autotestnet.when_failing_test.it_should_fail_first_test
          Failed    autotestnet.when_failing_test.it_should_fail_second_test
        console

        given_output "./test1.dll", console_output_dll1
        given_output "./test2.dll", console_output_dll2

        @test_runner.execute "SomeTestSpec"
        @test_runner.first_failed_test.should == <<-expected.gsub(/^ {10}/, '')
          Failed Tests:
          autotestnet.when_failing_other_test.it_should_fail_other_test
          Exception occured on following line
        expected
      end

      it "should aggregate output of both passing test executions" do
        expected_output = <<-output.gsub(/^ {10}/, '')
          All Passed:
          autotestnet.when_passing_other_test.it_should_pass_other_test

          All Passed:
          autotestnet.when_passing_test.it_should_pass_first_test

          autotestnet.when_passing_test.it_should_pass_second_test
          
          3 tests ran and passed
        output

        console_output_dll1 = <<-console.gsub(/^ {10}/, '')
          Passed    autotestnet.when_passing_other_test.it_should_pass_other_test
        console

        console_output_dll2 = <<-console.gsub(/^ {10}/, '')
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

        console_output_dll1 = <<-console.gsub(/^ {10}/, '')
          Passed    autotestnet.when_passing_other_test.it_should_pass_other_test
        console

        console_output_dll2 = <<-console.gsub(/^ {10}/, '')
          Passed    autotestnet.when_passing_test.it_should_pass_first_test
          Passed    autotestnet.when_passing_test.it_should_pass_second_test
        console

        given_output "./test1.dll", console_output_dll1
        given_output "./test2.dll", console_output_dll2

        @test_runner.execute "SomeTestSpec"
        @test_runner.test_results.split("\n").last.should == expected_output
      end

      it "should aggregate output of both inconclusive test executions" do
          expected_output = <<-output.gsub(/^ {12}/, '')
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
    
    def given_output(dll_name, output)
      @test_runner.stub!(:test_cmd).with(dll_name, "SomeTestSpec").and_return(dll_name)
      @sh.stub!(:execute).with(dll_name).and_return(output)
    end
  end
end
