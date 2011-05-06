require "./watcher_dot_net.rb"

describe NSpecRunner do
  before(:each) do
    @test_runner = NSpecRunner.new "." 
    $stdout.stub!(:puts) { }
  end

  it "should find nspec project dlls" do
    Dir.stub(:[]).and_return ['./SomeProj/bin/Debug/NSpec.dll']
    @test_runner.test_dlls.should == ['./SomeProj/bin/Debug/SomeProj.dll']
  end

  it "should set and get of nspec_path" do
    NSpecRunner.nspec_path = "c:\\nspec.exe"
    NSpecRunner.nspec_path.should == "c:\\nspec.exe"
  end

  it "should attempt to find latest version of nspec using major version" do
    Find.stub!(:find)
        .with(".")
        .and_yield("./packages/nspec.1.0.0/tools/NSpecRunner.exe")
        .and_yield("./packages/nspec.10.0.0/tools/NSpecRunner.exe")
        .and_yield("./packages/nspec.3.0.0/tools/NSpecRunner.exe")

    NSpecRunner.nspec_path = nil
    NSpecRunner.nspec_path.should == "./packages/nspec.10.0.0/tools/NSpecRunner.exe"
  end
  
  it "should attempt to find latest version of nspec using minor version" do
    Find.stub!(:find)
        .with(".")
        .and_yield("./packages/nspec.1.1.0/tools/NSpecRunner.exe")
        .and_yield("./packages/nspec.1.10.0/tools/NSpecRunner.exe")
        .and_yield("./packages/nspec.1.3.0/tools/NSpecRunner.exe")

    NSpecRunner.nspec_path = nil
    NSpecRunner.nspec_path.should == "./packages/nspec.1.10.0/tools/NSpecRunner.exe"
  end

  it "should attempt to find latest version of nspec using build version" do
    Find.stub!(:find)
        .with(".")
        .and_yield("./packages/nspec.1.0.1/tools/NSpecRunner.exe")
        .and_yield("./packages/nspec.1.0.10/tools/NSpecRunner.exe")
        .and_yield("./packages/nspec.1.0.3/tools/NSpecRunner.exe")

    NSpecRunner.nspec_path = nil
    NSpecRunner.nspec_path.should == "./packages/nspec.1.0.10/tools/NSpecRunner.exe"
  end
  
  it "should should resolve test command" do
    NSpecRunner.nspec_path = "nspec.exe"
    @test_runner.test_cmd("test1.dll", "SomeTestSpec").should == '"nspec.exe" "test1.dll" "SomeTestSpec"'
  end
end
