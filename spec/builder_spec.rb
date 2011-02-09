require "./watcher_dot_net.rb"


describe "each builder" do
  [
    { :builder => :MSBuilder },
    { :builder => :RakeBuilder }
  ].each do |item|
    it "#{item[:builder].to_s} should respond to new with folder being passed in" do
      Kernel.const_get(item[:builder].to_s).new "."
    end
  
    before(:each) { @builder = Kernel.const_get(item[:builder].to_s).new "." }
    it "#{item[:builder].to_s} should have execute method" do
      @builder.method(:execute).should_not == nil
    end    
  end
end
