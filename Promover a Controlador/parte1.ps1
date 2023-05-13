#
## Configurar zona horaria a UTC
#

Set-TimeZone -Id "Romance Standard Time"

Write-Output "Zona horaria cambiada."
Start-Sleep -Seconds 3

#
## Añadir al dominio
#

$hostname = HOSTNAME.EXE
$dominio = Read-Host "Introduzca el nombre de dominio"
$nombre = Read-Host "Introduzca un nuevo nombre para el servidor"

Add-Computer -ComputerName $hostname -DomainName $dominio -NewName $nombre -Credential $dominio\Administrator -Restart

Write-Output "Añadido al dominio $dominio."
Start-Sleep -Seconds 3