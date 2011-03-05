param($rootPath, $toolsPath, $package, $project)

$usageFile = $toolsPath + "\Usage.txt"

$configFileFrom = $toolsPath + "\dotnet.watchr.rb"
$configFileTo = "dotnet.watchr.rb"

$watchrFileFrom = $toolsPath + "\watcher_dot_net.rb"
$watchrFileTo = "watcher_dot_net.rb"

if(!(Test-Path $configFileTo))
{
  Copy-Item $configFileFrom $configFileTo
  Copy-Item $watchrFileFrom $watchrFileTo
  Start-Process $usageFile
}
