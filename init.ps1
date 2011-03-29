param($rootPath, $toolsPath, $package, $project)

$usageFile = $toolsPath + "\Usage.txt"

$configFileFrom = $toolsPath + "\dotnet.watchr.rb"
$configFileTo = "dotnet.watchr.rb"

$watchrFileFrom = $toolsPath + "\watcher_dot_net.rb"
$watchrFileTo = "watcher_dot_net.rb"

$redFileFrom = $toolsPath + "\red.png"
$redFileTo = "red.png"

$greenFileFrom = $toolsPath + "\green.png"
$greenFileTo = "green.png"

if(!(Test-Path $configFileTo))
{
  Copy-Item $configFileFrom $configFileTo
  Copy-Item $watchrFileFrom $watchrFileTo
  Copy-Item $redFileFrom $redFileTo
  Copy-Item $greenFileFrom $greenFileTo
  Start-Process $usageFile
}
