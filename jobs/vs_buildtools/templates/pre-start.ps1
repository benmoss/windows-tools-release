$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

$mtx = New-Object System.Threading.Mutex($false, "PathMutex")

if (!$mtx.WaitOne(300000)) {
  throw "Could not acquire PATH mutex"
}

$OldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
$vcRedistDir = "C:\var\vcap\packages\vs_buildtools\VC\Redist\MSVC\14.14.26405\x64\Microsoft.VC141.CRT"

if (-not $OldPath.Contains($vcRedistDir)) {
  $NewPath=$OldPath+';'+$vcRedistDir
  Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath
}

$mtx.ReleaseMutex()

