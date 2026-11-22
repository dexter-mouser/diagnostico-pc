# Umbrales y constantes del diagnóstico

# Semáforo
$ORDEN_ESTADOS = @{ gris = 0; verde = 1; amarillo = 2; rojo = 3 }
$TEXTO_ESTADOS = @{ gris = 'Sin datos'; verde = 'Bien'; amarillo = 'Revisar'; rojo = 'Mal' }

# Puntuación: se resta por cada apartado en amarillo o rojo
$PUNTOS_MAXIMOS = 100
$PENALIZACION_PUNTOS = @{ amarillo = 10; rojo = 25 }
$PUNTUACION_BIEN = 80
$PUNTUACION_REVISAR = 50

# Discos
$HORAS_DISCO_ALTAS = 20000
$DESGASTE_SSD_REVISAR = 50
$DESGASTE_SSD_MAL = 80

# Batería
$SALUD_BATERIA_BIEN = 80
$SALUD_BATERIA_REVISAR = 60
$CICLOS_BATERIA_ALTOS = 500

# Errores y actualizaciones
$DIAS_REVISION_EVENTOS = 90
$DIAS_SIN_ACTUALIZAR_REVISAR = 60
$DIAS_SIN_ACTUALIZAR_MAL = 180
$ANIOS_BIOS_ANTIGUA = 3

# Windows
$ID_APLICACION_WINDOWS = '55c92734-d682-4d71-983e-d6ec3f16059f'
$FORMATO_FECHA = 'dd/MM/yyyy'

# Webs de garantía por fabricante (patrón del nombre -> dirección)
$WEBS_GARANTIA = [ordered]@{
  'lenovo'     = 'https://pcsupport.lenovo.com/warranty-lookup'
  'hp|hewlett' = 'https://support.hp.com/checkwarranty'
  'dell'       = 'https://www.dell.com/support/home'
  'asus'       = 'https://www.asus.com/support/warranty-status-inquiry/'
}

# Programas de acceso remoto que el dueño anterior podría haber dejado
$PATRON_ACCESO_REMOTO = 'AnyDesk|TeamViewer|RustDesk|UltraViewer|Chrome Remote Desktop|Splashtop|LogMeIn|VNC|Supremo|Ammyy|ScreenConnect|ConnectWise|Radmin|Parsec|Sunlogin|AweSun|NoMachine|Zoho Assist|DWService|MeshAgent|GoToAssist|RemotePC|HopToDesk'

# Tecnologías de conexión de una pantalla integrada (WmiMonitorConnectionParams)
$CONEXIONES_PANTALLA_INTERNA = @(6, 11, 13, 2147483648)
$ANIOS_DIFERENCIA_PANTALLA = 2

# Códigos de error de dispositivos del Administrador de dispositivos
$CODIGO_DESCONECTADO = 45
$CODIGOS_ERROR_DISPOSITIVO = @{
  1 = 'Mal configurado'; 3 = 'Controlador dañado'; 10 = 'No puede iniciar'; 12 = 'Sin recursos suficientes'
  14 = 'Necesita reiniciar'; 18 = 'Hay que reinstalar el controlador'; 19 = 'Configuración dañada'
  22 = 'Deshabilitado'; 24 = 'No presente o sin controlador'; 28 = 'Sin controlador'
  31 = 'No funciona correctamente'; 39 = 'Controlador dañado o ausente'; 43 = 'Detenido por fallos'
}

# Dispositivos que se comprueban (EsNecesario: si falta, se marca para revisar)
$DISPOSITIVOS_ESPERADOS = [ordered]@{
  'Cámara'            = @{ Clases = @('Camera', 'Image'); Nombre = '.'; Excluir = $null; EsNecesario = $true }
  'Wi-Fi'             = @{ Clases = @('Net'); Nombre = 'Wi-?Fi|Wireless|WLAN|802\.11'; Excluir = 'Virtual|Direct|Miniport'; EsNecesario = $true }
  'Bluetooth'         = @{ Clases = @('Bluetooth'); Nombre = '.'; Excluir = $null; EsNecesario = $true }
  'Sonido'            = @{ Clases = @('MEDIA'); Nombre = 'Audio|Sound|Sonido'; Excluir = 'NVIDIA|AMD|Virtual|HDMI|Display|Streaming'; EsNecesario = $true }
  'Lector de huellas' = @{ Clases = @('Biometric'); Nombre = '.'; Excluir = $null; EsNecesario = $false }
}

# Estados de BitLocker que devuelve el Explorador (System.Volume.BitLockerProtection)
$ESTADOS_BITLOCKER = @{ 1 = 'Activado'; 2 = 'Desactivado'; 3 = 'Cifrando'; 4 = 'Descifrando'; 5 = 'Activado (en pausa)'; 6 = 'Activado (bloqueado)' }

# Requisitos básicos de Windows 11
$RAM_MINIMA_WINDOWS_11_GB = 4
$DISCO_MINIMO_WINDOWS_11_GB = 64

# Piezas cambiadas: valores genéricos que deja una placa nueva sin programar
$PATRON_SERIE_GENERICA = 'To be filled|Default string|O\.E\.M\.|System Serial|Serial Number|Not Applicable|Not Specified|^None$|^0+$|^1234567|^x+$'
$PATRON_UUID_GENERICO = '^(0{8}-0{4}-0{4}-0{4}-0{12}|F{8}-F{4}-F{4}-F{4}-F{12})$'
$DIAS_EQUIPO_USADO = 365
$HORAS_DISCO_NUEVO = 200

# Activadores piratas de Windows
$PATRON_ACTIVADORES = 'KMS|AutoPico|AAct|Activator|SECOH|KMSELDI|HWIDGen|MAS_AIO'
$RUTAS_ACTIVADORES = @(
  '%windir%\KMSAutoS', '%ProgramData%\KMSAutoS', '%ProgramData%\KMSAuto', '%windir%\AAct_Tools'
  '%ProgramFiles%\KMSpico', '%ProgramData%\Online_KMS_Activation', '%windir%\SECOH-QAD.exe'
  '%windir%\SECOH-QAD.dll', '%windir%\System32\SECOH-QAD.exe', '%windir%\System32\SppExtComObjHook.dll'
  '%windir%\System32\SppExtComObjPatcher.exe'
)

# Procesador: texto que delata un cambio del nombre en el registro
$PATRON_CAMBIO_PROCESADOR = 'ProcessorNameString|CentralProcessor'
$PATRON_MODELO_PROCESADOR = 'Core\s*Ultra\s*\d+\s*\w+|i[3579]-\w+|Ryzen\s*(AI\s*)?\d+\s*\w+|Celeron\s*\w+|Pentium\s*\w+|Athlon\s*\w+|Snapdragon\s*\w+(\s*\w+)?|\bN\d{2,4}\b'

# Prueba de rendimiento
$SEGUNDOS_PRUEBA_UN_HILO = 5
$SEGUNDOS_PRUEBA_TODOS_HILOS = 15
$MEGAS_PRUEBA_DISCO = 1024
$GIGAS_LIBRES_PRUEBA_DISCO = 3
$RENDIMIENTO_CPU_REVISAR = 70
$RENDIMIENTO_CPU_MAL = 40
$VELOCIDAD_MINIMA_DISCO = @{ NVMe = 300; SSD = 150; HDD = 50 }
