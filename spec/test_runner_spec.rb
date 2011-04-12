describe TestRunner do
  before(:each) { @test_runner = TestRunner.new "." }
  
  describe "finding impacted tests" do
    it "should return nil if solution file changed" do
      @test_runner.find('SomeSolution.sln').should == nil
    end

    it "should return nil if project file changed" do
      @test_runner.find('TestProj.csproj').should == nil
    end

    it "should return nil if file doesn't contain an extension" do
      @test_runner.find('TestProj/').should == nil
    end

    it "if file name doesn't start with describe_, should append describe_" do
      @test_runner.find('Person.cs').should == 'describe_Person'
    end

    it "if file with describe_, should just return file" do
      @test_runner.find('Person.cs').should == 'describe_Person'
    end
  end

  describe "finding test dlls" do
    it "should find a dll ending in test.dll" do
      Find.stub!(:find).with(".").and_yield("./SomeProjTest/bin/debug/SomeProjTest.dll")
      @test_runner.test_dlls[0].should == "./SomeProjTest/bin/debug/SomeProjTest.dll"
    end

    it "should find a dll ending in spec.dll" do
      Find.stub!(:find).with(".").and_yield("./SomeProjTest/bin/debug/SomeProjSpec.dll")
      @test_runner.test_dlls[0].should == "./SomeProjTest/bin/debug/SomeProjSpec.dll"
    end

    it "should find a dll ending in specs.dll" do
      Find.stub!(:find).with(".").and_yield("./SomeProjTest/bin/debug/SomeProjSpecs.dll")
      @test_runner.test_dlls[0].should == "./SomeProjTest/bin/debug/SomeProjSpecs.dll"
    end

    it "should find a dll ending in tests.dll" do
      Find.stub!(:find).with(".").and_yield("./SomeProjTest/bin/debug/SomeProjTests.dll")
      @test_runner.test_dlls[0].should == "./SomeProjTest/bin/debug/SomeProjTests.dll"
    end

    it "should disregard the nspec.dll" do
      Find.stub!(:find).with(".").and_yield("./SomeProjTest/bin/debug/NSpec.dll")
      @test_runner.test_dlls.count.should == 0
    end


    it "should allow for the redefinition of test_dlls" do
      @test_runner.test_dlls = ["first.dll", "second.dll"]

      @test_runner.test_dlls[0].should == "first.dll"
      @test_runner.test_dlls[1].should == "second.dll"
    end

    [ { :path => "./SomeProjTest/bin/obj/SomeProjTest.dll", :desc => "test file in bin obj" },
      { :path => "./TestResults/output/2005-12-31/SomeProjTest.dll", :desc => "test file in automated MSTests" }
    ].each do |kvp|
      it "should ignore test files in #{kvp[:desc]}" do
        @test_runner.test_dlls[0].should == nil
      end
    end

    it "should find multiple tests dlls" do
      Find.stub!(:find)
          .with(".")
          .and_yield("./SomeProjTest/bin/debug/SomeProjTest.dll")
          .and_yield("./SomeOtherProjTests/bin/debug/SomeOtherProjTests.dll")

      @test_runner.test_dlls[0].should == "./SomeProjTest/bin/debug/SomeProjTest.dll"
      @test_runner.test_dlls[1].should == "./SomeOtherProjTests/bin/debug/SomeOtherProjTests.dll"
    end

    it "should find dll for file that is inside of a test project" do
      Find.stub!(:find).with(".").and_yield("./SomeProjTest/bin/debug/SomeProjTest.dll")

      @test_runner.get_test_dll_for('./SomeProjTest/test_file.cs').should == "./SomeProjTest/bin/debug/SomeProjTest.dll"
    end

    it "should return null if file is not in test project" do
      Find.stub!(:find).with(".").and_yield("./SomeProjTest/bin/debug/SomeProjTest.dll")

      @test_runner.get_test_dll_for('./Model/Person.cs').should == nil
    end
  end
end
