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

    [ { :file_name => "Person.svc.cs",  },
      { :file_name => "Person.feature.cs" }
    ].each do |kvp|
      it "if file has subsequent extentions, each one should be remove" do
        @test_runner.find(kvp[:file_name]).should == 'describe_Person'
      end
    end

    it "if file with describe_, should just return file" do
      @test_runner.find('Person.cs').should == 'describe_Person'
    end

    it "if path contains describe_, should return that part of the path" do
      @test_runner.find('./test/describe_Person/when_saving_person.cs').should == 'describe_Person'
    end

    it "if path and file both contain describe_, should return describe of folder" do
      @test_runner.find('./test/describe_Other/describe_Person.cs').should == 'describe_Other'
    end
  end
end
