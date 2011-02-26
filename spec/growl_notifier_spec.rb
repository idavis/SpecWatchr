require "./watcher_dot_net.rb"

describe GrowlNotifier do
  before(:each) { @array = Array.new }

  context "something that works in rspec but not nspec" do
    context "sibling context" do
      before(:each) { @array << "sibling 1" }

      it { @array.count.should == 1 }
    end

    context "another sibling context" do
      before(:each) { @array << "sibling 2" }

      it { @array.count.should == 1 }
    end
  end
end
