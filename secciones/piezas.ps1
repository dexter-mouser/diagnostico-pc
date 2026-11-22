# Apartado: indicios de placa base o disco cambiados

function Probar-EsGenerico($valor, $patron) {
  return -not "$valor".Trim() -or "$valor".Trim() -match $patron
}

# Fecha más antigua del hardware: BIOS instalada o fabricación de la pantalla integrada
function Obtener-FechaReferenciaEquipo {
  $fechas = @()
  $fechaBios = (Get-CimInstance Win32_BIOS).ReleaseDate
  if ($fechaBios) { $fechas += [datetime]$fechaBios }
  try {
    $pantalla = @(Obtener-Monitores) | Where-Object { $_.EsInterna -and $_.Anio } | Select-Object -First 1
    if ($pantalla) { $fechas += (Get-Date -Year $pantalla.Anio -Month 1 -Day 1).AddDays(7 * [int]$pantalla.Semana) }
  } catch { }
  return $fechas | Sort-Object | Select-Object -First 1
}

function Evaluar-Placa($identificadores) {
  $genericos = @()
  foreach ($nombre in $identificadores.Keys) {
    $patron = $(if ($nombre -eq 'UUID del equipo') { $PATRON_UUID_GENERICO } else { $PATRON_SERIE_GENERICA })
    if (Probar-EsGenerico $identificadores[$nombre] $patron) { $genericos += $nombre }
  }
  if ($genericos.Count -eq 0) { return @{ Estado = 'verde'; Motivos = @() } }
  return @{
    Estado  = 'amarillo'
    Motivos = @("Valores genéricos en: $($genericos -join ', '). Suele pasar cuando se cambia la placa base y no se reprograma.")
  }
}

function Evaluar-DiscoNuevo($fechaReferencia, $horasDisco) {
  if (-not $fechaReferencia -or $null -eq $horasDisco) { return @{ Estado = 'gris'; Motivos = @() } }
  $diasEquipo = ((Get-Date) - $fechaReferencia).TotalDays
  if ($diasEquipo -ge $DIAS_EQUIPO_USADO -and $horasDisco -lt $HORAS_DISCO_NUEVO) {
    return @{
      Estado  = 'amarillo'
      Motivos = @("El disco tiene solo $horasDisco horas de uso en un equipo de unos $([math]::Floor($diasEquipo / 365)) año(s): probablemente se cambió. Pregunta por qué.")
    }
  }
  return @{ Estado = 'verde'; Motivos = @() }
}

function Obtener-Piezas {
  $bios = Get-CimInstance Win32_BIOS
  $placa = Get-CimInstance Win32_BaseBoard
  $producto = Get-CimInstance Win32_ComputerSystemProduct
  $identificadores = [ordered]@{
    'Número de serie del equipo' = $bios.SerialNumber
    'Número de serie de la placa' = $placa.SerialNumber
    'UUID del equipo'            = $producto.UUID
  }
  $horasDisco = $null
  try { $horasDisco = (Get-PhysicalDisk | Get-StorageReliabilityCounter | Measure-Object PowerOnHours -Maximum).Maximum } catch { }
  $fechaReferencia = Obtener-FechaReferenciaEquipo
  $placaEvaluada = Evaluar-Placa $identificadores
  $discoEvaluado = Evaluar-DiscoNuevo $fechaReferencia $horasDisco
  $filas = [ordered]@{}
  foreach ($nombre in $identificadores.Keys) { $filas[$nombre] = $identificadores[$nombre] }
  $filas['Fecha de referencia del equipo'] = Formatear-Fecha $fechaReferencia
  $filas['Horas de uso del disco'] = $(if ($null -ne $horasDisco) { "$horasDisco h" } else { 'Requiere administrador' })
  return @{
    Titulo  = 'Piezas cambiadas'
    Estado  = Obtener-PeorEstado @($placaEvaluada.Estado, $discoEvaluado.Estado)
    Motivos = @($placaEvaluada.Motivos) + @($discoEvaluado.Motivos)
    Cuerpo  = (Nueva-Tabla $filas) + '<p>Un cambio de pieza no es malo en sí, pero el vendedor debería explicarlo. Revisa también el apartado Pantalla.</p>'
  }
}
