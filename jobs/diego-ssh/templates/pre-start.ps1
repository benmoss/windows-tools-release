﻿$ErrorActionPreference = "Stop";
trap { $host.SetShouldExit(1) }

$mtx = New-Object System.Threading.Mutex($false, "PathMutex")

if (!$mtx.WaitOne(5000)) {
  throw "Could not acquire PATH mutex"
}

$ssh_home="C:\"

Invoke-WebRequest -Uri https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub -OutFile "$ssh_home\authorized_key" -UseBasicParsing
$env:SSH_AUTHORIZEDKEY="$(cat $ssh_home\authorized_key)"
Set-ItemProperty -Path "$env:HKLM_ENV" -Name SSH_AUTHORIZEDKEY -Value $env:SSH_AUTHORIZEDKEY

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $env:SERVICE_WRAPPER_URL -OutFile "$ssh_home\service-wrapper.exe" -UseBasicParsing
$XML=@"
<service>
  <id>sshd</id>
  <name>sshd</name>
  <description>Start sshd</description>
  <executable>$ssh_home\\sshd.exe</executable>
  <arguments>-authorizedKey="%SSH_AUTHORIZEDKEY%" -address="0.0.0.0:22" -inheritDaemonEnv=true</arguments>
  <logmode>rotate</logmode>
</service>
"@
Set-Content -Value $XML -Path "$ssh_home\\service-wrapper.xml" -Encoding 'UTF8'
Start-Process -FilePath "$ssh_home\\service-wrapper.exe" -ArgumentList "install" -Wait -NoNewWindow -PassThru

netsh advfirewall firewall add rule name="SSHD" dir=in action=allow service=sshd enable=yes
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
netsh advfirewall firewall add rule name="SSHD" dir=in action=allow program="$ssh_home\sshd.exe" enable=yes
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
netsh advfirewall firewall add rule name="ssh" dir=in action=allow protocol=TCP localport=22
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

$GoRoot='C:\var\vcap\packages\golang-windows\go'

$OldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
$AddedFolder="$GoRoot\bin"

if (-not $OldPath.Contains($AddedFolder)) {
  $NewPath=$OldPath+';'+$AddedFolder
  Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath
}

Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name GOROOT -Value $GoRoot

$mtx.ReleaseMutex()
