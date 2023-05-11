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

$TaskName = "part2" # Especifica el nombre de la tarea que se creó anteriormente
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false

Restart-Computer