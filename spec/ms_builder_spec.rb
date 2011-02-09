require "./watcher_dot_net.rb"

describe MSBuilder do
  describe "when initializing ms builder" do
    before(:each) do 
      Find.stub!(:find).with(".").and_yield("App.sln").and_yield("App/app.csproj")
      @ms_builder = MSBuilder.new "."
    end

    it "should find the sln file to build" do
      @ms_builder.sln_file.should == "App.sln"
    end

    it "should default ms_build_directory" do
      @ms_builder.build_cmd("App.sln").should == "\"C:\\Windows\\Microsoft.NET\\Framework\\v4.0.30319\\MSBuild.exe\" \"App.sln\" /verbosity:quiet /nologo"
    end

    context "has multiple solutions files in other directories" do
      before(:each) { Find.stub!(:find)
                          .with(".")
                          .and_yield("./App.Proj/app_2.sln")
                          .and_yield("./App.sln") }

      it "should look for the solution file only in the root" do
        @ms_builder.sln_file.should == "./App.sln"
      end
    end
  end
end
