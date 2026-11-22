# Apartado: procesador, memoria y gráficas

function Obtener-Componentes {
  $filas = [ordered]@{}
  foreach ($procesador in @(Get-CimInstance Win32_Processor)) {
    $filas['Procesador'] = "$($procesador.Name.Trim()) · $($procesador.NumberOfCores) núcleos / $($procesador.NumberOfLogicalProcessors) hilos"
  }
  $modulos = @(Get-CimInstance Win32_PhysicalMemory)
  $totalGb = [math]::Round(($modulos | Measure-Object Capacity -Sum).Sum / 1GB)
  $filas['Memoria RAM total'] = "$totalGb GB en $($modulos.Count) módulo(s)"
  $numero = 1
  foreach ($modulo in $modulos) {
    $filas["Módulo de RAM $numero"] = "$([math]::Round($modulo.Capacity / 1GB)) GB · $($modulo.Speed) MHz · $("$($modulo.Manufacturer) $($modulo.PartNumber)".Trim())"
    $numero++
  }
  $numero = 1
  foreach ($grafica in @(Get-CimInstance Win32_VideoController)) {
    $filas["Gráfica $numero"] = "$($grafica.Name) (controlador $($grafica.DriverVersion))"
    $numero++
  }
  return @{
    Titulo  = 'Componentes'
    Estado  = $null
    Motivos = @('Compara estos datos con los del anuncio: procesador, RAM y gráfica.')
    Cuerpo  = Nueva-Tabla $filas
  }
}
