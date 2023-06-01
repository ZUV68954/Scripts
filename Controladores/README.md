# Actualizar controladores de Dominio

## Instalación de Windows Server Core

En primer lugar, crearemos una máquina nueva que será el futuro controlador de dominio principal. El nombre será **DC03-01.wargamesX**. Mantendremos la configuración por defecto que vCenter sugiere para Windows Server 2016 o versiones posteriores pero cambiando las opciones de disco duro a **aprovisionamiento fino** y la red a **PG-VLAN20**. Utilizaremos la última ISO del almacén para Windows Server 2022.

![Imagen de las características de la máquina](../doc/Server-Core/creacion-maquina.jpg)

Arrancaremos desde la imagen y cambiaremos la distribución de teclado, presionaremos Install, diremos que no tenemos clave de producto, elegiremos la versión **Windows Server 2022 Standard**, elegiremos la opción personalizada y el disco en el que se instalará Windows.

![Teclado](../doc/Server-Core/teclado.jpg)

![Edición](../doc/Server-Core/edicion.jpg)

![Personalizada](../doc/Server-Core/personalizada.png)

![Disco](../doc/Server-Core/disco.jpg)


## Post-Instalación

Una vez terminada la instalación, habrá que configurar la red, habilitar el escritorio remoto (para poder subir los scripts) e instalar las Tools de VMware.

Windows Server Core cuenta con un menú llamado SConfig desde el que podremos realizar fácilmente la configuración inicial del equipo.

![SConfig](../doc/Server-Core/sconfig.jpg)

### Red

Para instalar la red seguiremos estos pasos, la configuración se realiza introduciendo una entrada desde el teclado y presionando intro para confirmar, la configuración de red es la número 8, por lo que habrá que escribir 8 y presionar intro.

Una vez ahí elegiremos la interfaz, que queremos configurar escribiendo su número de índice y presionando intro.

Ahí veremos tres opciones, la primera es para asignar **IP**, **máscara de red** y **puerta de enlace**, deberemos seleccionar la opción de IP estática. La configuración que he elegido yo ha sido:

| **IP**        | **Máscara de Red**           | **Gateway**  |
| ------------- |:-------------:| -----:|
| 172.20.10.22      | 255.255.255.0 | 172.20.10.1 |

Luego en la segunda opción, elegiremos como servidores DNS a los controladores de dominio ya existentes, **si no lo hacemos la máquina no podrá resolver el dominio ni unirse a él.**

Existe la posibilidad de que la máquina sea incapaz de liberar el DHCP de forma automática, en ese caso podremos utilizar los siguientes comandos para desactivar el DHCP y configurar la dirección IP.

```PowerShell
Remove-NetIPAddress -InterfaceAlias Ethernet0 -confirm:$False
```
```PowerShell
New-NetIPAddress -InterfaceAlias Ethernet0 -IPAddress 172.20.10.22 -PrefixLength 24 -DefaultGateway 172.20.10.1
```


### Escritorio Remoto

La configuración del escritorio remoto será tanto de lo mismo, presionaremos en el siguiente orden *7 > Intro > e > Intro > 2 > Intro > Intro*.


### VMware Tools

Presionaremos en *Instalar VMware Tools…* en vCenter, esto nos montará el disco de las tools.

![VMware Tools](../doc/Server-Core/tools.jpg)


Ahora en el servidor instalaremos las Tools de la siguiente forma:

* Abriremos PowerShell (15).
* Abriremos la unidad de disco que por defecto será D:, en caso de que no lo fuere, es posible listar los volúmenes montados en Windows con el siguente comando: *Get-PSDrive -PSProvider 'FileSystem'*.
* Ejecutaremos la instalación con *.\setup.exe*.
* Nos dejaremos guiar por el isntalador gráfico y reiniciaremos la máquina.


## Promover a controlador

Subiremos mediante RDP los scripts *parte1.ps1* y *parte2.ps1* al servidor, ahí los ejecutaremos y se terminará de configurar la máquina y también se unirá al dominio y se convertirá en controlador.

## Cambio en los Roles Maestros

Bastará con seguir la siguiente [guía de Microsoft](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/upgrade-domain-controllers#:~:text=Add%20a%20new%20domain%20controller%20with%20a%20newer%20version%20of%20Windows%20Server), de ella tomaremos este comando, en el que **"DC03-10"** es el nombre del servidor al que queremos transferir los roles maestros, los comandos habrá que ponerlos en el servidor que posea los roles maestros:
**ES OBLIGATORIO UTILIZAR EL MÓDULO DE ACTIVE DIRECTORY PARA POWERSHELL**
```PowerShell
Move-ADDirectoryServerOperationMasterRole -Identity "DC03-10" -OperationMasterRole 0,1,2,3,4
```

Podremos comprobar que los roles maestros han cambiado con los siguentes comandos:
```PowerShell
Get-ADDomain | FL InfrastructureMaster, RIDMaster, PDCEmulator
```
```PowerShell
Get-ADForest | FL DomainNamingMaster, SchemaMaster
```

El resultado deberá ser similar a este, *(mi controlador se llama DC-Core)*:

![Cambio-rol-maestro](../doc/Server-Core/roles-cambiados.jpg)


## Instalar herramientas de administración en la estación.

Bastará con ejecutar el siguiente script en una máquina unida a nuestro dominio:

```PowerShell
#
## Script para configurar la estación.
#

#
## Gestión de errores
#

$error.clear()
$ErrorActionPreference = "Stop"

#
## Comprobar si el script se está ejecutando como administrador.
#

$admin = [Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544'

if ($admin = "True") {
    #
    ## Instalar el paquete de idioma necesario.
    #

    if (Get-InstalledLanguage -Language en-US) {
        Write-Output "Todos los paquetes de idiomas necesarios están instalados."
    } else {
            Write-Output "Instalando paquete de idiomas de Estados Unidos."
            try {
                Install-Language en-US
            }
            catch {
                "Error a la hora de instalar el paquete de idiomas: $error"; exit
            }
            if (!$error) { "Paquetes de idiomas instalados correctamente." }
        }
    try {
        Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability –Online
    }
    catch {
        "Error a la hora de instalar RSAT: $error"; exit
    }
    if (!$error) { "RSAT instalados correctamente." }
  } else {
    Write-Output "Es necesario ejecutar este script como administrador."
  }
```
## Degradar el controlador de dominio.

**A continuación se explica como degradar el controlador de dominio, sin embargo, parece ser que se crean errores sin previo aviso que terminan impidiendo que el dominio funcione, se recomienda no degradar ningún controlador.**

Para degradar el controlador de dominio será necesario quitarle los roles al servidor, de forma automática Windows nos dirá que degrademos el controlador.

![Remove](../doc/Server-Core/remove.jpg)

Presionaremos en *Active Directory Domain Services* y ahí nos saldrá un mensaje de error indicándonos que debemos degradar el controlador, será lo que haremos.

![Demote](../doc/Server-Core/demote.jpg)

Dejaremos todas las opciones por defecto salvo la de *Remove DNS delegation*. Si nos encontramos con que no podemos avanzar en el wizard, es posible que debamos forzar al controlador de dominio, la opción está en la primera pestaña.

![Credenciales](../doc/Server-Core/credenciales.jpg)

## Limpiar metadatos ?

Aún queda esclarecer si se debe hacer esto -_-.