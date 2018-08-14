$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

$mtx = New-Object System.Threading.Mutex($false, "PathMutex")

if (!$mtx.WaitOne(300000)) {
  throw "Could not acquire PATH mutex"
}

$installDir = "c:\python27"
$msiFile = (Get-ChildItem "c:\var\vcap\packages\python/*.msi").FullName
Start-Process -FilePath msiexec -ArgumentList "/i $msiFile /qn ALLUSERS=1 ADDLOCAL=ALL TargetDir=$installDir" -Wait -NoNewWindow

$OldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path

if (-not $OldPath.Contains($installDir)) {
  $NewPath=$OldPath+';'+$installDir
  Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath
}

$mtx.ReleaseMutex()
