#
## Configurar zona horaria a UTC
#

Set-TimeZone -Id "Romance Standard Time"

Write-Output "Zona horaria cambiada."
Start-Sleep -Seconds 5

#
## Añadir al dominio
#

$hostname = HOSTNAME.EXE
$dominio = Read-Host "Introduzca el nombre de dominio"
$nombre = Read-Host "Introduzca un nuevo nombre para el servidor"

Add-Computer -ComputerName $hostname -DomainName $dominio -NewName $nombre -Credential $dominio\Administrator -Restart

Write-Output "Añadido al dominio $dominio."
Start-Sleep -Seconds 5

#
## Crear tarea
#

$action = New-ScheduledTaskAction -Execute "powershell.exe" -ExecutionPolicy Bypass -File 'C:\Users\Administrator\Documents\part2.ps1'
$trigger = New-ScheduledTaskTrigger -AtLogon
$settings = New-ScheduledTaskSettingsSet
$Trigger.Delay = "PT5S"
$task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings
Register-ScheduledTask -TaskName "part2" -InputObject $task

Add-Content -Path "C:\Users\Administrator\Documents\part2.ps1" -value @"

#
## Añadir roles de Controlador
#

Add-WindowsFeature AD-Domain-Services, DNS

#
# Configuración como controlador de dominio.
#

$dominio = Read-Host 'Nombre de dominio'

Import-Module ADDSDeployment
Install-ADDSDomainController `
-NoGlobalCatalog:$false `
-CreateDnsDelegation:$false `
-Credential (Get-Credential) `
-CriticalReplicationOnly:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainName "$dominio" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SiteName "Default-First-Site-Name" `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true

Write-Output "Configurado como controlador de dominio en $dominio."
Start-Sleep -Seconds 5

#
## Eliminar la tarea creada
#

$TaskDelete = "part2" # Especifica el nombre de la tarea que se creó anteriormente
Unregister-ScheduledTask -TaskName $TaskDelete -Confirm:$false

Restart-Computer
"@