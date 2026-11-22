# Apartado: mini prueba de rendimiento del procesador y del disco

# Código C# para cargar el procesador con varios hilos y escribir en el disco sin caché
$CODIGO_PRUEBA_RENDIMIENTO = @'
using System;
using System.Diagnostics;
using System.IO;
using System.Security.Cryptography;
using System.Threading;
using System.Threading.Tasks;

public static class PruebaRendimiento {
  // Calcula SHA-256 en bucle y devuelve los MB procesados por segundo
  public static double MedirProcesador(int hilos, int segundos) {
    long totalBytes = 0;
    DateTime fin = DateTime.UtcNow.AddSeconds(segundos);
    Thread[] lista = new Thread[hilos];
    for (int i = 0; i < hilos; i++) {
      lista[i] = new Thread(() => {
        byte[] datos = new byte[1048576];
        new Random(1).NextBytes(datos);
        long local = 0;
        using (SHA256 sha = new SHA256Managed()) {
          while (DateTime.UtcNow < fin) { sha.ComputeHash(datos); local += datos.Length; }
        }
        Interlocked.Add(ref totalBytes, local);
      });
      lista[i].IsBackground = true;
      lista[i].Start();
    }
    foreach (Thread hilo in lista) hilo.Join();
    return totalBytes / 1048576.0 / segundos;
  }

  public static Task<double> IniciarProcesador(int hilos, int segundos) {
    return Task.Run(() => MedirProcesador(hilos, segundos));
  }

  // Escribe un archivo saltándose la caché y devuelve los MB escritos por segundo
  public static double MedirEscrituraDisco(string ruta, int megas) {
    byte[] bloque = new byte[4 * 1048576];
    new Random(2).NextBytes(bloque);
    Stopwatch reloj = Stopwatch.StartNew();
    using (FileStream archivo = new FileStream(ruta, FileMode.Create, FileAccess.Write, FileShare.None, 4096, FileOptions.WriteThrough)) {
      for (int escrito = 0; escrito < megas; escrito += 4) archivo.Write(bloque, 0, bloque.Length);
      archivo.Flush(true);
    }
    reloj.Stop();
    return megas / reloj.Elapsed.TotalSeconds;
  }
}
'@

function Cargar-PruebaRendimiento {
  if (-not ('PruebaRendimiento' -as [type])) { Add-Type -TypeDefinition $CODIGO_PRUEBA_RENDIMIENTO -Language CSharp }
}

# Mide la carga y toma cada segundo el % de rendimiento del procesador (frecuencia frente a la base)
function Medir-Procesador($hilos, $segundos) {
  $tarea = [PruebaRendimiento]::IniciarProcesador($hilos, $segundos)
  $muestras = @()
  while (-not $tarea.IsCompleted) {
    Start-Sleep -Seconds 1
    $muestra = Get-CimInstance Win32_PerfFormattedData_Counters_ProcessorInformation -Filter "Name='_Total'" -ErrorAction SilentlyContinue
    if ($muestra) { $muestras += [int]$muestra.PercentProcessorPerformance }
  }
  return @{ MegasPorSegundo = [math]::Round($tarea.Result); Muestras = @($muestras | Select-Object -Skip 1) }
}

function Obtener-TipoDiscoSistema {
  try {
    $numero = (Get-Partition -DriveLetter $env:SystemDrive.TrimEnd(':') -ErrorAction Stop).DiskNumber
    $disco = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq "$numero" } | Select-Object -First 1
    if ("$($disco.BusType)" -eq 'NVMe') { return 'NVMe' }
    if ("$($disco.MediaType)" -eq 'SSD') { return 'SSD' }
  } catch { }
  return 'HDD'
}

function Medir-Disco {
  $libreGb = (Get-PSDrive $env:SystemDrive.TrimEnd(':')).Free / 1GB
  if ($libreGb -lt $GIGAS_LIBRES_PRUEBA_DISCO) { return $null }
  $ruta = Join-Path $env:TEMP 'diagnostico-prueba-disco.tmp'
  try {
    return [math]::Round([PruebaRendimiento]::MedirEscrituraDisco($ruta, $MEGAS_PRUEBA_DISCO))
  } finally {
    Remove-Item $ruta -ErrorAction SilentlyContinue
  }
}

function Probar-EstaEnchufado {
  try { return [bool](Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus -ErrorAction Stop | Select-Object -First 1).PowerOnline } catch { return $true }
}

function Evaluar-Rendimiento($datos) {
  $estados = @()
  $motivos = @()
  if (-not $datos.EstaEnchufado) {
    $estados += 'gris'
    $motivos += 'El equipo estaba en batería: conecta el cargador y repite la prueba para que sea válida.'
  } elseif ($null -ne $datos.PromedioCarga) {
    $estado = 'verde'
    if ($datos.PromedioCarga -lt $RENDIMIENTO_CPU_MAL) { $estado = 'rojo' } elseif ($datos.PromedioCarga -lt $RENDIMIENTO_CPU_REVISAR) { $estado = 'amarillo' }
    if ($estado -ne 'verde') { $motivos += "Con carga, el procesador trabaja al $($datos.PromedioCarga) % de su velocidad base: se frena por calor (polvo, pasta térmica seca) o por un modo de ahorro." }
    $estados += $estado
  }
  if ($null -ne $datos.Disco) {
    $minimo = $VELOCIDAD_MINIMA_DISCO[$datos.TipoDisco]
    if ($datos.Disco -lt $minimo) { $estados += 'amarillo'; $motivos += "El disco escribe a $($datos.Disco) MB/s, lento para un disco $($datos.TipoDisco) (lo normal es más de $minimo MB/s)." } else { $estados += 'verde' }
  }
  return @{ Estado = Obtener-PeorEstado $estados; Motivos = $motivos }
}

function Obtener-Rendimiento {
  Write-Host "  Prueba de rendimiento en curso (unos $($SEGUNDOS_PRUEBA_UN_HILO + $SEGUNDOS_PRUEBA_TODOS_HILOS + 10) s): no uses el equipo."
  Cargar-PruebaRendimiento
  $procesador = @(Get-CimInstance Win32_Processor)[0]
  $hilos = [int]$procesador.NumberOfLogicalProcessors
  $unHilo = Medir-Procesador 1 $SEGUNDOS_PRUEBA_UN_HILO
  $todos = Medir-Procesador $hilos $SEGUNDOS_PRUEBA_TODOS_HILOS
  $datos = @{
    EstaEnchufado = Probar-EstaEnchufado
    PromedioCarga = $(if ($todos.Muestras.Count -gt 0) { [math]::Round(($todos.Muestras | Measure-Object -Average).Average) } else { $null })
    TipoDisco     = Obtener-TipoDiscoSistema
    Disco         = Medir-Disco
  }
  $evaluacion = Evaluar-Rendimiento $datos
  $filas = [ordered]@{
    'Procesador, un hilo'           = "$($unHilo.MegasPorSegundo) MB/s"
    "Procesador, $hilos hilos"      = "$($todos.MegasPorSegundo) MB/s ($([math]::Round($todos.MegasPorSegundo / [math]::Max(1, $unHilo.MegasPorSegundo), 1)) veces un hilo)"
    'Velocidad media con carga'     = $(if ($null -ne $datos.PromedioCarga) { "$($datos.PromedioCarga) % de la base (≈ $([math]::Round($procesador.MaxClockSpeed * $datos.PromedioCarga / 100000, 2)) GHz)" } else { $null })
    'Velocidad mínima con carga'    = $(if ($todos.Muestras.Count -gt 0) { "$(($todos.Muestras | Measure-Object -Minimum).Minimum) % de la base" } else { $null })
    "Escritura en disco ($($datos.TipoDisco))" = $(if ($null -ne $datos.Disco) { "$($datos.Disco) MB/s" } else { "No se probó: hacen falta $GIGAS_LIBRES_PRUEBA_DISCO GB libres" })
    'Con el cargador conectado'     = Convertir-SiNo $datos.EstaEnchufado
  }
  $cuerpo = (Nueva-Tabla $filas) + '<p>Las cifras del procesador sirven para comparar con otro equipo con el mismo procesador. Esta prueba no detecta discos con capacidad falsa: para eso hay que llenar el disco con un programa como H2testw.</p>'
  return @{ Titulo = 'Rendimiento'; Estado = $evaluacion.Estado; Motivos = $evaluacion.Motivos; Cuerpo = $cuerpo }
}
