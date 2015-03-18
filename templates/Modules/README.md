## Plantilla para módulos Powershell
###Instrucciones
Modificar los ficheros y copiarlos en una carpeta dentro de una de las rutas de:

```
Get-Item Env:PSModulePath
```
  
###Importación en la consola  
Para trabajar con los módulos son importantes:
```
Get-Module -ListAvailable
```
`Get-Module` lista los módulos cargados en la sesión de la consola actual, con el parámetro `-ListAvailable` se listarían los módulos que estan disponibles para ser importados.

```
Import-Module MODULO
```
Utilizar la sentencia anterior para importar el módulo `MODULO`.

```
Remove-Module MODULO
```
Utilizar la sentencia anterior para eliminar las funciones y álias que se importaron anteriormente.
