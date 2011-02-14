require './watcher_dot_net.rb'

@dw = WatcherDotNet.new ".", { :builder => :MSBuilder, :test_runner => :NUnitRunner }

MSTestRunner.ms_test_path = 
  "C:\\program files (x86)\\microsoft visual studio 10.0\\common7\\ide\\mstest.exe"

MSBuilder.ms_build_path =
  "C:\\Windows\\Microsoft.NET\\Framework\\v4.0.30319\\MSBuild.exe"

NUnitRunner.nunit_path = 
  "C:\\program files (x86)\\nunit 2.5.9\\bin\\net-2.0\\nunit-console-x86.exe"

#set to empty string if you dont have growl installed
GrowlNotifier.growl_path = 
  "C:\\program files (x86)\\Growl for Windows\\growlnotify.exe"

def handle filename
	@dw.consider filename
  `touch dotnet.watchr.rb`
end
	
watch ('.*.cs$') { |md| handle md[0] }
watch ('.*.csproj$') { |md| handle md[0] }
