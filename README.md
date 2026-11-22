# Diagnóstico de portátil de segunda mano

Script para Windows que revisa un portátil antes de comprarlo y genera un informe HTML. El informe tiene una puntuación de 0 a 100, y cada apartado lleva un semáforo: **Bien**, **Revisar**, **Mal** o **Sin datos**.

## Uso

1. Copia la carpeta completa a una USB.
2. En el portátil que vas a comprar, abre la USB y haz doble clic en `ejecutar.bat`.
3. Acepta el aviso de administrador. Sin permisos de administrador no se pueden leer los datos SMART de los discos ni el estado exacto de BitLocker.
4. Deja el cargador conectado y no uses el equipo durante alrededor de un minuto (incluye una prueba de rendimiento). El informe se abre solo en el navegador.

No instala nada y funciona sin internet. Los informes se guardan en la USB, en `informes/<número de serie>-<fecha>/`.

## Qué revisa

| Apartado | Datos |
|---|---|
| Equipo | Fabricante, modelo, número de serie, placa base, BIOS y versión de Windows |
| Componentes | Procesador, módulos de RAM y gráficas |
| Autenticidad del procesador | Compara el nombre, los núcleos y los hilos que da Windows con los del firmware (SMBIOS), y busca tareas, programas de arranque o archivos de inicio que cambien el nombre del procesador en el registro |
| Rendimiento | Carga el procesador con un hilo y con todos (unos 20 s) y mide si se frena con la carga. Mide también la velocidad de escritura del disco del sistema con un archivo temporal de 1 GB |
| Pantalla | Fabricante y código del panel, tamaño, año de fabricación, resolución y frecuencia actuales |
| Dispositivos | Cámara, Wi-Fi, Bluetooth, sonido y lector de huellas detectados, y dispositivos con error en el Administrador de dispositivos |
| Discos | Salud según Windows, horas encendido, veces encendido, desgaste, temperatura y errores sin corregir (SMART) |
| Batería | Capacidad original frente a la actual, porcentaje de salud y ciclos. Incluye además el informe completo de Windows (`bateria.html`) |
| Piezas cambiadas | Números de serie y UUID genéricos (señal de placa base cambiada) y disco con muy pocas horas en un equipo con más de un año |
| Antigüedad aproximada | Fecha de la BIOS, fabricación de la pantalla, primera instalación de Windows registrada (incluye las actualizaciones de versión), instalación actual, evento más antiguo y horas de uso del disco. Enlace a la web de garantía según el fabricante |
| Licencia y bloqueos | Si Windows está activado, el tipo de licencia (OEM, Retail o por volumen), si hay clave en la BIOS, rastros de activadores piratas (servidor KMS fijado, archivos, gancho de KMS_VL_ALL, tareas y servicios) y si el equipo está unido a una empresa |
| Seguridad | Chip TPM, arranque UEFI, arranque seguro, BitLocker, antivirus activo y requisitos básicos de Windows 11 |
| Programas | Programas de acceso remoto (instalados, servicios o en ejecución), programas que arrancan con Windows y lista de programas instalados |
| Actualizaciones | Versión de Windows, última actualización instalada, días sin actualizar y fecha de la BIOS |
| Errores (90 días) | Pantallazos azules, apagados inesperados, errores de hardware (WHEA) y errores de disco |
| Revisión manual | Lista para marcar durante la visita y botones de color para buscar píxeles muertos |
| Pruebas externas | Programas recomendados para pruebas más largas (estrés, RAM y sensores) |

## Cómo se decide el semáforo

Los umbrales están en `nucleo/configuracion.ps1`:

- **Procesador:** mal si el modelo que da Windows no coincide con el del firmware o si hay programas que cambian su nombre; revisar si no coinciden los núcleos o el nombre del registro.
- **Rendimiento:** revisar si con carga el procesador baja de media al 70 % de su velocidad base y mal si baja del 40 %; revisar si el disco escribe por debajo de 300 MB/s (NVMe), 150 MB/s (SSD) o 50 MB/s (HDD). En batería no se evalúa el procesador.
- **Piezas cambiadas:** revisar si hay números de serie o UUID genéricos, o si el disco tiene menos de 200 horas en un equipo de más de un año. La edad del equipo se toma de la fecha más antigua entre la BIOS y la fabricación de la pantalla.
- **Pantalla:** se marca para revisar si el panel se fabricó 2 años o más después que la BIOS, porque probablemente se cambió.
- **Dispositivos:** se marca para revisar si falta la cámara, el Wi-Fi, el Bluetooth o el sonido, o si algún dispositivo tiene error.
- **Disco:** revisar con un desgaste igual o superior al 50 %, con más de 20 000 horas encendido o si no se pudieron leer los datos SMART; mal con un desgaste igual o superior al 80 %, con errores sin corregir o si Windows lo marca como defectuoso.
- **Batería:** bien si conserva el 80 % o más de su capacidad, revisar entre el 60 % y el 79 %, y mal por debajo del 60 %. También se marca para revisar con 500 ciclos o más.
- **Licencia:** mal si Windows no está activado, si hay rastros de activadores piratas, si usa activación KMS sin pertenecer a una empresa o si el equipo está unido a una empresa; revisar si la licencia es por volumen.
- **Seguridad:** revisar si no hay TPM, si el arranque seguro está desactivado, si el disco está cifrado con BitLocker, si no hay antivirus activo o si tiene Windows 10; mal si tiene Windows 10 y no cumple los requisitos de Windows 11.
- **Programas:** revisar si hay programas de acceso remoto.
- **Actualizaciones:** revisar con 60 días o más sin actualizar y mal con 180 o más.
- **Errores:** según la cantidad de cada tipo. Un registro que empieza hace menos de 90 días se marca para revisar, porque indica que se reinstaló Windows o se borró el historial.

## Puntuación

Parte de 100 y resta 10 puntos por cada apartado en **Revisar** y 25 por cada apartado en **Mal**. Con 80 o más se considera bien; entre 50 y 79, para revisar; por debajo de 50, mal.

## Estructura

```
ejecutar.bat        Abre el diagnóstico como administrador
diagnostico.ps1     Carga las piezas, ejecuta los apartados y guarda el informe
plantilla.html      Diseño del informe (estilos y prueba de pantalla)
nucleo/
  configuracion.ps1 Umbrales, puntuación y listas (acceso remoto, activadores, dispositivos)
  utilidades.ps1    Funciones comunes (fechas, semáforo, permisos)
  consultas.ps1     Consultas al sistema que usan varios apartados (pantallas, dispositivos)
  html.ps1          Piezas del informe, resumen y puntuación
secciones/          Un archivo por apartado del informe
informes/           Se crea al ejecutar; un informe por equipo y fecha
```

## Cómo funciona

`diagnostico.ps1` carga todos los archivos de `nucleo/` y `secciones/`. Después ejecuta cada apartado, que devuelve su título, su estado, los motivos y el HTML de su contenido. Si un apartado falla, aparece como «Sin datos» y el informe sigue adelante. Por último, `nucleo/html.ps1` calcula la puntuación y rellena `plantilla.html`.

Para agregar un apartado, crea un archivo en `secciones/` con una función `Obtener-<Apartado>` y añádela a la lista de `diagnostico.ps1`. Los `.ps1` deben guardarse en UTF-8 con BOM, porque si no, PowerShell 5.1 muestra mal los acentos.

Con la variable de entorno `DIAGNOSTICO_SIN_ABRIR=1`, el informe se genera sin abrirse en el navegador (útil para pruebas).

## Límites

- Windows no guarda la fecha de la primera activación. La fecha real de fabricación y la de compra se consultan con el número de serie en la web del fabricante.
- Algunos discos o controladores no informan todos los datos SMART; en ese caso aparece «No disponible».
- Sin permisos de administrador, el estado de BitLocker puede quedar sin confirmar.
- La compatibilidad con Windows 11 no revisa el modelo del procesador.
- El script confía en lo que informan Windows y el firmware. Una falsificación hecha en el firmware, o una activación digital pirata (HWID), no se detecta.
- No detecta discos con capacidad falsa: para eso hay que llenar el disco con un programa como H2testw.
- No sabe qué piezas traía el equipo de fábrica: compara RAM, disco y pantalla con la ficha del modelo.
- Las temperaturas bajo carga necesitan un programa externo, como HWiNFO u OCCT.
