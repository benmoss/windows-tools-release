$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

$mtx = New-Object System.Threading.Mutex($false, "PathMutex")

if (!$mtx.WaitOne(5000)) {
  throw "Could not acquire PATH mutex"
}

$OldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
$AddedFolder="c:\var\vcap\packages\msys2"

if (-not $OldPath.Contains($AddedFolder)) {
  $NewPath=$AddedFolder+';'+$OldPath
  Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath
}

#https://github.com/msys2/msys2/wiki/MSYS2-installation
Write-Host "Starting initialization via msys2_shell.cmd"
Start-Process "$AddedFolder\msys2_shell.cmd" -Wait -ArgumentList '-c', exit

Write-Host "Repeating system update until there are no more updates or max 5 iterations"
$ErrorActionPreference = 'Continue'
Set-Alias bash "$AddedFolder\usr\bin\bash.exe"
while (!$done) {
    Write-Host "`n================= SYSTEM UPDATE $((++$i)) =================`n"
    bash -lc 'pacman --noconfirm -Syuu | tee /update.log'
    $done = (Get-Content $AddedFolder\update.log) -match 'there is nothing to do' | Measure-Object | ForEach-Object { $_.Count -eq 2 }
    $done = $done -or ($i -ge 5)
}
Remove-Item $AddedFolder\update.log -ea 0

$mtx.ReleaseMutex()
