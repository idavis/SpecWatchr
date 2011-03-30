require "./watcher_dot_net.rb"

describe NSpecRunner do
  before(:each) do
    @test_runner = NSpecRunner.new "." 
    $stdout.stub!(:puts) { }
  end
  it "should all for set and get of nspec_path" do
    NSpecRunner.nspec_path = "c:\\nspec.exe"
    NSpecRunner.nspec_path.should == "c:\\nspec.exe"
  end

  it "should should resolve test command" do
    NSpecRunner.nspec_path = "nspec.exe"
    @test_runner.test_cmd("test1.dll", "SomeTestSpec").should == '"nspec.exe" "test1.dll" "SomeTestSpec"'
  end

  describe "when executing tests" do
    before(:each) do
      @sh = mock("CommandShell")
      CommandShell.stub!(:new).and_return(@sh)
      @sh.stub!(:execute).and_return("")
      @test_runner = NSpecRunner.new "."
    end

    it "should execute tests against each dll" do
      @test_runner.stub!(:test_dlls).and_return(["./test1.dll", "./test2.dll" ])
      
      @sh.should_receive(:execute).twice()

      @test_runner.execute "SomeTestSpec"

    end
  end

  describe "statuses" do
    before(:each) do
      @sh = mock("CommandShell")
      CommandShell.stub!(:new).and_return(@sh)
      @test_runner = NSpecRunner.new "."
      @sh.stub!(:execute).and_return""
      @test_runner.stub!(:test_dlls).and_return(["./test1.dll"])
    end

    it "should marked as failed if output contains **** FAILURES ****" do
      test_output = <<-OUTPUT.gsub(/^ {8}/, '')
        when outputting
          should output - FAILED - Expected: 1, But was: 2
          should pass

        **** FAILURES ****

        when outputting. should output. - FAILED
        Expected: 1, But was: 2

        stack trace line 1
        stack trace line 2
        stack trace line 3
        stack trace line 4
      OUTPUT

      given_output "./test1.dll", test_output

      @test_runner.execute "SomeTestSpec"
      @test_runner.failed.should == true
    end
  end

  describe "output formatting" do
    before(:each) do
      @sh = mock("CommandShell")
      CommandShell.stub!(:new).and_return(@sh)
      @test_runner = NSpecRunner.new "."
      @sh.stub!(:execute).and_return""
      @test_runner.stub!(:test_dlls).and_return(["./test1.dll"])
    end

    it "should pass along output provided by NSpecRunner.exe" do
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

    it "it should set first_failed_test" do
      expected_output = <<-OUTPUT.gsub(/^ {8}/, '')
        when outputting
          should pass
          should output - FAILED - Expected: 1, But was: 2

        **** FAILURES ****

        when outputting. should output. - FAILED
        Expected: 1, But was: 2

      OUTPUT

      given_output "./test1.dll", expected_output

      @test_runner.execute "SomeTestSpec"
      @test_runner.first_failed_test.should == <<-expected.gsub(/^ {8}/, '')
        Failed Tests:
        when outputting. should output. - FAILED
        Expected: 1, But was: 2

      expected
    end

    it "it should set first_failed_test and include stack trace" do
      expected_output = <<-OUTPUT.gsub(/^ {8}/, '')
        describe specifications
          when creating specifications
            true should be false - FAILED - Expected: False, But was: True
            enumerable should be empty
            enumerable should contain 1
            enumerable should not contain 1 - FAILED - Expected: collection containing 2, But was: < 1 >
            1 should be 2 - FAILED - Expected: 2, But was: 1
            1 should be 1
            1 should not be 1 - FAILED - Expected: not 1, But was: 1
            1 should not be 2
            "" should not be null
            spec should not be null - FAILED - Expected: not null, But was: null

        **** FAILURES ****

        describe specifications. when creating specifications. true should be false.
        Expected: False, But was: True
           at NUnit.Framework.Assert.That(Object actual, IResolveConstraint expression, String message, Object[] args)
           at NUnit.Framework.Assert.IsFalse(Boolean condition)
           at NSpec.AssertionExtensions.should_be_false(Boolean actual) in c:\Users\Amir\NSpec\NSpec\AssertionExtensions.cs:line 32
           at describe_specifications.<when_creating_specifications>b__0() in c:\Users\Amir\NSpec\SampleSpecs\WebSite\describe_specifications.cs:line 7
           at NSpec.Domain.Example.Run(Context context) in c:\Users\Amir\NSpec\NSpec\Domain\Example.cs:line 38

        describe specifications. when creating specifications. enumerable should not contain 1.
        Expected: collection containing 2, But was: < 1 >
           at NUnit.Framework.Assert.That(Object actual, IResolveConstraint expression, String message, Object[] args)
           at NUnit.Framework.CollectionAssert.Contains(IEnumerable collection, Object actual, String message, Object[] args)
           at NUnit.Framework.CollectionAssert.Contains(IEnumerable collection, Object actual)
           at NSpec.AssertionExtensions.should_contain[T](IEnumerable`1 collection, T t) in c:\Users\Amir\NSpec\NSpec\AssertionExtensions.cs:line 82
           at describe_specifications.<when_creating_specifications>b__3() in c:\Users\Amir\NSpec\SampleSpecs\WebSite\describe_specifications.cs:line 10
           at NSpec.Domain.Example.Run(Context context) in c:\Users\Amir\NSpec\NSpec\Domain\Example.cs:line 38

        describe specifications. when creating specifications. 1 should be 2.
        Expected: 2, But was: 1
           at NUnit.Framework.Assert.That(Object actual, IResolveConstraint expression, String message, Object[] args)
           at NUnit.Framework.Assert.AreEqual(Object expected, Object actual)
           at NSpec.AssertionExtensions.should_be(Object actual, Object expected) in c:\Users\Amir\NSpec\NSpec\AssertionExtensions.cs:line 42
           at describe_specifications.<when_creating_specifications>b__4() in c:\Users\Amir\NSpec\SampleSpecs\WebSite\describe_specifications.cs:line 11
           at NSpec.Domain.Example.Run(Context context) in c:\Users\Amir\NSpec\NSpec\Domain\Example.cs:line 38

        describe specifications. when creating specifications. 1 should not be 1.
        Expected: not 1, But was: 1
           at NUnit.Framework.Assert.That(Object actual, IResolveConstraint expression, String message, Object[] args)
           at NUnit.Framework.Assert.AreNotEqual(Object expected, Object actual)
           at NSpec.AssertionExtensions.should_not_be(Object actual, Object expected) in c:\Users\Amir\NSpec\NSpec\AssertionExtensions.cs:line 47
           at describe_specifications.<when_creating_specifications>b__6() in c:\Users\Amir\NSpec\SampleSpecs\WebSite\describe_specifications.cs:line 13
           at NSpec.Domain.Example.Run(Context context) in c:\Users\Amir\NSpec\NSpec\Domain\Example.cs:line 38

        describe specifications. when creating specifications. spec should not be null.
        Expected: not null, But was: null
           at NUnit.Framework.Assert.That(Object actual, IResolveConstraint expression, String message, Object[] args)
           at NUnit.Framework.Assert.IsNotNull(Object anObject)
           at NSpec.AssertionExtensions.should_not_be_null(Object o) in c:\Users\Amir\NSpec\NSpec\AssertionExtensions.cs:line 12
           at describe_specifications.<when_creating_specifications>b__9() in c:\Users\Amir\NSpec\SampleSpecs\WebSite\describe_specifications.cs:line 16
           at NSpec.Domain.Example.Run(Context context) in c:\Users\Amir\NSpec\NSpec\Domain\Example.cs:line 38

        10 Examples, 5 Failed, 0 Pending
      OUTPUT

      given_output "./test1.dll", expected_output

      @test_runner.execute "SomeTestSpec"
      @test_runner.first_failed_test.should == <<-expected.gsub(/^ {8}/, '')
        Failed Tests:
        describe specifications. when creating specifications. true should be false.
        Expected: False, But was: True
           at NUnit.Framework.Assert.That(Object actual, IResolveConstraint expression, String message, Object[] args)
           at NUnit.Framework.Assert.IsFalse(Boolean condition)
           at NSpec.AssertionExtensions.should_be_false(Boolean actual) in c:\Users\Amir\NSpec\NSpec\AssertionExtensions.cs:line 32
           at describe_specifications.<when_creating_specifications>b__0() in c:\Users\Amir\NSpec\SampleSpecs\WebSite\describe_specifications.cs:line 7
           at NSpec.Domain.Example.Run(Context context) in c:\Users\Amir\NSpec\NSpec\Domain\Example.cs:line 38

      expected
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
  end
  
  def given_output(dll_name, output)
    @test_runner.stub!(:test_cmd)
                .with(dll_name, "SomeTestSpec")
                .and_return(dll_name)

    @sh.stub!(:execute).with(dll_name).and_return(output)
  end
end
