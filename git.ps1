$nombre_usuario = Read-Host 'Nombre de usuario de Git'
$token = Read-Host 'Token de Git'
$wingetList = winget list

if ($wingetList | Select-String "Git.Git") {
    winget install Git.Git -h
}

#
# Configuración de Git.
#

git.exe config --global credential.helper store
git.exe config --global credential.username $nombre_usuario
git.exe config --global credential.helper '!f() { echo ''password=$token''; }; f'

Write-Output 'Git configurado correctamente'