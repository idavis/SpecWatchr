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

  describe "when executing tests" do
    before(:each) do
      @sh = mock("CommandShell")
      CommandShell.stub!(:new).and_return(@sh)
      @test_runner = NUnitRunner.new "."
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
        
        context "given output is: Test run: 0 (inconclusive)" do
          it "should mark test run as inconclusive" do
            test_output = <<-OUTPUT.gsub(/^ {14}/, '')
              ProcessModel: Default    DomainUsage: Single
              Execution Runtime: Default
              Included categories: Repository

              Tests run: 0, Errors: 0, Failures: 0, Inconclusive: 0, Time: 0.0050003 seconds
                Not run: 0, Invalid: 0, Ignored: 0, Skipped: 0
            OUTPUT

            given_output "./test1.dll", test_output

            @test_runner.execute "SomeTestSpec"
            @test_runner.inconclusive.should == true
          end
        end

        context "given output contains failing tests" do
          it "should mark test run as failed if assertion failed (Test Failed)" do
            test_output = <<-OUTPUT.gsub(/^ {14}/, '')
              ProcessModel: Default    DomainUsage: Single
              Execution Runtime: Default
              Included categories: Repository
              ***** when_retrieving.should_retrieve
              ***** when_deleting.should_delete

              Tests run: 2, Errors: 0, Failures: 1, Inconclusive: 0, Time: 3.7712157 seconds
                Not run: 0, Invalid: 0, Ignored: 0, Skipped: 0

              Errors and Failures:
              1) Test Failure : when_retrieving.should_retrieve
            OUTPUT

            given_output "./test1.dll", test_output

            @test_runner.execute "SomeTestSpec"
            @test_runner.failed.should == true
          end

        end

        context "given output contains no failing tests" do
          it "should mark test run as passed" do
            output = <<-OUTPUT
              Included categories: TemplatesController
              ***** when_creating.should_create
              ***** when_deleting.should_delete
              ***** when_deleting.should_return

              Tests run: 3, Errors: 0, Failures: 0, Inconclusive: 0, Time: 0.752043 seconds
                Not run: 0, Invalid: 0, Ignored: 0, Skipped: 0
            OUTPUT

            given_output "./test1.dll", output

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
            given_output "./test1.dll", "Tests run: 0"
            given_output "./test2.dll", "Tests run: 0"
            
            @test_runner.execute "SomeTestSpec"
            @test_runner.inconclusive.should == true
            @test_runner.failed.should == false
          end
        end

        context "given failures exist for at least one dll" do
          it "should mark test run as failed" do
            given_output "./test1.dll", "Errors and Failures:"
            given_output "./test2.dll", "Tests run: 0"

            @test_runner.execute "SomeTestSpec"
            @test_runner.failed.should == true
            @test_runner.inconclusive.should == false
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
            given_output "./test2.dll", "Tests run: 0"
            
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
        @test_runner = NUnitRunner.new "."
        @sh.stub!(:execute).and_return("")
        @test_runner.stub!(:test_dlls).and_return(["./test1.dll"])
      end

      context "is : \"No tests to execute\"" do
        it "should return no specs found" do
          expected_output = <<-OUTPUT.gsub(/^ {12}/, '')
            Test Inconclusive:
            No tests found under SomeTestSpec

          OUTPUT

          given_output "./test1.dll", "Tests run: 0"

          @test_runner.execute "SomeTestSpec"
          @test_runner.test_results.should == expected_output
        end
      end

      context "has failing tests" do
        context "single behavioral test under spec" do
          [
            { :failure_type => "Test Error" },
            { :failure_type => "Test Failure" },
            { :failure_type => "TearDown Error" },
            { :failure_type => "SetUp Error" }
          ].each do |kvp|
            it "should mark test run as failed if test threw exception (#{ kvp[:failure_type] })" do
              expected_output = <<-output.gsub(/^ {16}/, '')
                Failed Tests:
                when failing test
                    it should fail first test
                        Exception occured on following line

              output

              console_output = <<-console.gsub(/^ {16}/, '')
                ProcessModel: Default    DomainUsage: Single
                Execution Runtime: Default
                Included categories: Repository
                ***** when_failing_test.it_should_fail_first_test
               
                Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0, Time: 3.7712157 seconds
                  Not run: 0, Invalid: 0, Ignored: 0, Skipped: 0

                Errors and Failures:
                1) #{ kvp[:failure_type] } : when_failing_test.it_should_fail_first_test
                Exception occured on following line
              console

              given_output "./test1.dll", console_output

              @test_runner.execute "SomeTestSpec"
              @test_runner.test_results.should == expected_output
            end
          end

          it "should format test output with nice tabs" do
            expected_output = <<-output.gsub(/^ {14}/, '')
              Failed Tests:
              when failing test
                  it should fail first test
                      Exception occured on following line

            output

            console_output = <<-console.gsub(/^ {14}/, '')
              ProcessModel: Default    DomainUsage: Single
              Execution Runtime: Default
              Included categories: Repository
              ***** when_failing_test.it_should_fail_first_test
             
              Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0, Time: 3.7712157 seconds
                Not run: 0, Invalid: 0, Ignored: 0, Skipped: 0

              Errors and Failures:
              1) Test Failure : when_failing_test.it_should_fail_first_test
              Exception occured on following line
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
              ProcessModel: Default    DomainUsage: Single
              Execution Runtime: Default
              Included categories: Repository
              ***** when_failing_test.it_should_fail_first_test
             
              Tests run: 1, Errors: 0, Failures: 1, Inconclusive: 0, Time: 3.7712157 seconds
                Not run: 0, Invalid: 0, Ignored: 0, Skipped: 0

              Errors and Failures:
              1) Test Failure : when_failing_test.it_should_fail_first_test
              Exception occured on following line
            console

            given_output "./test1.dll", console_output

            @test_runner.execute "SomeTestSpec"
            @test_runner.first_failed_test.should == <<-expected.gsub(/^ {14}/, '')
              Failed Tests:
              when failing test
                  it should fail first test
                      Exception occured on following line

            expected
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

              console_output = <<-console.gsub(/^ {16}/, '')
                ProcessModel: Default    DomainUsage: Single
                Execution Runtime: Default
                Included categories: Repository
                ***** when_failing_test.it_should_fail_first_test
                ***** when_failing_test.it_should_fail_first_test2

                Tests run: 2, Errors: 0, Failures: 2, Inconclusive: 0, Time: 3.7712157 seconds
                  Not run: 0, Invalid: 0, Ignored: 0, Skipped: 0

                Errors and Failures:
                1) Test Failure : when_failing_test.it_should_fail_first_test
                Exception occured on following line
                line 2

                2) Test Failure : when_failing_test.it_should_fail_first_test2
                Exception occured on following line
                another lines of error
                yet some more
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
              ***** autotestnet.when_passing_test.it_should_pass_first_test
              ***** autotestnet.when_passing_test.it_should_pass_second_test
              
              Tests run: 3, Errors: 0, Failures: 0, Inconclusive: 0, Time: 0.752043 seconds
                Not run: 0, Invalid: 0, Ignored: 0, Skipped: 0
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
              Included categories: TemplatesController
              ***** when_passing_other_test.it_should_pass_other_test
              ***** when_passing_test.it_should_pass_second_test
              ***** when_passing_test.it_should_pass_first_test

              Tests run: 3, Errors: 0, Failures: 0, Inconclusive: 0, Time: 0.752043 seconds
                Not run: 0, Invalid: 0, Ignored: 0, Skipped: 0
            console

            given_output "./test1.dll", console_output

            @test_runner.execute "SomeTestSpec"
            @test_runner.test_results.should == expected_output
          end

          it "should have last line stating how many tests passed" do
            expected_output = "3 tests ran and passed"

            console_output = <<-console.gsub(/^ {14}/, '')
              Included categories: TemplatesController
              ***** when_passing_other_test.it_should_pass_other_test
              ***** when_passing_test.it_should_pass_second_test
              ***** when_passing_test.it_should_pass_first_test

              Tests run: 3, Errors: 0, Failures: 0, Inconclusive: 0, Time: 0.752043 seconds
                Not run: 0, Invalid: 0, Ignored: 0, Skipped: 0
            console

            given_output "./test1.dll", console_output

            @test_runner.execute "SomeTestSpec"
            @test_runner.test_results.split("\n").last.should == expected_output
          end
        end
      end

      context "multiple dlls" do
        before { @test_runner.stub!(:test_dlls).and_return(["./test1.dll", "./test2.dll"]) }

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
            ProcessModel: Default    DomainUsage: Single
            Execution Runtime: Default
            Included categories: Repository
            ***** when_failing_other_test.it_should_fail_other_test

            Tests run: 1, Errors: 1, Failures: 2, Inconclusive: 0, Time: 3.7712157 seconds
              Not run: 0, Invalid: 0, Ignored: 0, Skipped: 0

            Errors and Failures:
            1) Test Failure : when_failing_other_test.it_should_fail_other_test
          console

          console_output_dll2 = <<-console.gsub(/^ {12}/, '')
            ProcessModel: Default    DomainUsage: Single
            Execution Runtime: Default
            Included categories: Repository
            ***** when_failing_test.it_should_fail_first_test
            ***** when_failing_test.it_should_fail_second_test

            Tests run: 2, Errors: 0, Failures: 2, Inconclusive: 0, Time: 3.7712157 seconds
              Not run: 0, Invalid: 0, Ignored: 0, Skipped: 0

            Errors and Failures:
            1) Test Failure : when_failing_test.it_should_fail_first_test

            2) Test Failure : when_failing_test.it_should_fail_second_test
          console

          given_output "./test1.dll", console_output_dll1
          given_output "./test2.dll", console_output_dll2

          @test_runner.execute "SomeTestSpec"
          @test_runner.test_results.should == expected_output
        end

        it "should only show failed test output even if another dll has all tests passed" do
          expected_output = <<-output.gsub(/^ {12}/, '')
            Failed Tests:
            when failing test
                it should fail first test

                it should fail second test

          output

          console_output_dll1 = <<-console.gsub(/^ {12}/, '')
            ***** autotestnet.when_passing_other_test.it_should_pass_other_test
          console

          console_output_dll2 = <<-console.gsub(/^ {12}/, '')
            ProcessModel: Default    DomainUsage: Single
            Execution Runtime: Default
            Included categories: Repository
            ***** when_failing_test.it_should_fail_first_test
            ***** when_failing_test.it_should_fail_second_test

            Tests run: 2, Errors: 0, Failures: 2, Inconclusive: 0, Time: 3.7712157 seconds
              Not run: 0, Invalid: 0, Ignored: 0, Skipped: 0

            Errors and Failures:
            1) Test Failure : when_failing_test.it_should_fail_first_test

            2) Test Failure : when_failing_test.it_should_fail_second_test
          console

          given_output "./test1.dll", console_output_dll1
          given_output "./test2.dll", console_output_dll2

          @test_runner.execute "SomeTestSpec"
          @test_runner.test_results.should == expected_output
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
            ***** autotestnet.when_passing_other_test.it_should_pass_other_test
          console

          console_output_dll2 = <<-console.gsub(/^ {12}/, '')
            ***** autotestnet.when_passing_test.it_should_pass_first_test
            ***** autotestnet.when_passing_test.it_should_pass_second_test
          console

          given_output "./test1.dll", console_output_dll1
          given_output "./test2.dll", console_output_dll2

          @test_runner.execute "SomeTestSpec"
          @test_runner.test_results.should == expected_output
        end

        it "should aggregate output of both inconclusive test executions" do
          expected_output = <<-output.gsub(/^ {12}/, '')
            Test Inconclusive:
            No tests found under SomeTestSpec

            Test Inconclusive:
            No tests found under SomeTestSpec
            
          output

          given_output "./test1.dll", "Tests run: 0" 
          given_output "./test2.dll", "Tests run: 0"

          @test_runner.execute "SomeTestSpec"
          @test_runner.test_results.should == expected_output
        end

        it "should not display inconclusive if tests were found in at least one test suite" do
          expected_output = <<-output.gsub(/^ {12}/, '')
            Failed Tests:
            when failing other test
                it should fail other test
                    Error on line 1

          output

          console_output_dll1 = <<-console.gsub(/^ {12}/, '')
            ProcessModel: Default    DomainUsage: Single
            Execution Runtime: Default
            Included categories: Repository
            ***** when_failing_other_test.it_should_fail_other_test

            Tests run: 1, Errors: 1, Failures: 2, Inconclusive: 0, Time: 3.7712157 seconds
              Not run: 0, Invalid: 0, Ignored: 0, Skipped: 0

            Errors and Failures:
            1) Test Failure : when_failing_other_test.it_should_fail_other_test
            Error on line 1
          console

          console_output_dll2 = <<-console.gsub(/^ {12}/, '')
            ProcessModel: Default    DomainUsage: Single
            Execution Runtime: Default
            Included categories: Repository

            Tests run: 0, Errors: 0, Failures: 2, Inconclusive: 0, Time: 3.7712157 seconds
              Not run: 0, Invalid: 0, Ignored: 0, Skipped: 0
          console

          given_output "./test1.dll", console_output_dll1
          given_output "./test2.dll", console_output_dll2

          @test_runner.execute "SomeTestSpec"
          @test_runner.test_results.should == expected_output
        end
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
