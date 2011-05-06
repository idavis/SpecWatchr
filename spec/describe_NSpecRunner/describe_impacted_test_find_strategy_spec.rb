require "./watcher_dot_net.rb"

describe NSpecRunner do
  before(:each) do
    @test_runner = NSpecRunner.new "." 
    $stdout.stub!(:puts) { }
    @changed_file = "./SomeProjectTests/when_saving_person.cs" 
    @dll = ["./SomeProjectTests/bin/Debug/SomeProjTest.dll"]
    Dir.stub(:[]).and_return @dll
  end

  describe "impacted test find strategy for nspec" do
    context "implentation file changed" do
      before(:each) { @changed_file = "./SomeProject/Person.cs" }

      it "should run class naming convension describe_#{@changed_file}" do
        @test_runner.find(@changed_file).should == "describe_Person"
      end
     
      it "should return nill if base TestRunner evaulates changed file as nil" do
        @test_runner.find("Test.sln").should == nil 
      end
    end

    context "test file changed" do
      before(:each) { @changed_file = "./SomeProjectTests/describe_Person.cs" }

      it "should return #{@changed_file} w/o the extension as result" do
        @test_runner.find(@changed_file).should == "describe_Person"
      end
    end

    context "test file under a folder changed" do
      before(:each) { @changed_file = "./SomeProjectTests/describe_Person/when_saving_person.cs" }

      it "should return the folder name including class name" do
        @test_runner.find(@changed_file).should == 'describe_Person\.when_saving_person'
      end
    end

    context "test file does not start with describe, but is inside a test project" do
      it "should return dll_folder without ./ prefix" do
        @test_runner.root_folder(@dll[0]).should == "SomeProjectTests"
      end

      it "should return name of test file even though it doesn't match name" do
        @test_runner.find(@changed_file).should == "when_saving_person"
      end
    end
  end
end
