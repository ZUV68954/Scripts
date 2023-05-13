#
## Añadir roles de Controlador
#

Add-WindowsFeature AD-Domain-Services, DNS

#
# Configuración como controlador de dominio.
#

$dominio = Read-Host 'Nombre de dominio'
$admin = Read-Host 'Usuario administrador'

Install-ADDSDomainController `
 -DomainName "$dominio" `
 -Credential (Get-Credential "$dominio\$admin") `
 -InstallDns:$true

Write-Output "Configurado como controlador de dominio en $dominio."
Start-Sleep -Seconds 3