param($rootPath, $toolsPath, $package, $project)

$configFileFrom = $toolsPath + "\dotnet.watchr.rb"
$configFileTo = "dotnet.watchr.rb"

$watchrFileFrom = $toolsPath + "\watcher_dot_net.rb"
$watchrFileTo = "watcher_dot_net.rb"

Copy-Item $configFileFrom $configFileTo
Copy-Item $watchrFileFrom $watchrFileTo
