# Apartado: errores registrados en los últimos días

function Contar-Eventos($filtro) {
  $filtro.LogName = 'System'
  $filtro.StartTime = (Get-Date).AddDays(-$DIAS_REVISION_EVENTOS)
  try {
    return @(Get-WinEvent -FilterHashtable $filtro -ErrorAction Stop).Count
  } catch {
    if ($_.FullyQualifiedErrorId -like 'NoMatchingEventsFound*') { return 0 }
    return $null
  }
}

function Obtener-Errores {
  $conteos = [ordered]@{
    'Pantallazos azules'             = @{ Filtro = @{ ProviderName = 'Microsoft-Windows-WER-SystemErrorReporting'; Id = 1001 }; Revisar = 1; Mal = 3 }
    'Apagados inesperados'           = @{ Filtro = @{ ProviderName = 'Microsoft-Windows-Kernel-Power'; Id = 41 }; Revisar = 3; Mal = 10 }
    'Errores graves de hardware'     = @{ Filtro = @{ ProviderName = 'Microsoft-Windows-WHEA-Logger'; Level = 1, 2 }; Revisar = 1; Mal = 1 }
    'Errores corregidos de hardware' = @{ Filtro = @{ ProviderName = 'Microsoft-Windows-WHEA-Logger'; Level = 3 }; Revisar = 1; Mal = 50 }
    'Errores de disco'               = @{ Filtro = @{ ProviderName = 'disk', 'Ntfs', 'stornvme', 'storahci'; Level = 1, 2, 3 }; Revisar = 1; Mal = 10 }
  }
  $filas = [ordered]@{}
  $estados = @()
  $motivos = @()
  foreach ($nombre in $conteos.Keys) {
    $regla = $conteos[$nombre]
    $cantidad = Contar-Eventos $regla.Filtro
    $estado = Evaluar-Cantidad $cantidad $regla.Revisar $regla.Mal
    $estados += $estado
    if ($estado -eq 'amarillo' -or $estado -eq 'rojo') { $motivos += "${nombre}: $cantidad en los últimos $DIAS_REVISION_EVENTOS días." }
    $filas[$nombre] = $cantidad
  }
  $eventoMasAntiguo = Get-WinEvent -LogName System -Oldest -MaxEvents 1 -ErrorAction SilentlyContinue
  if ($eventoMasAntiguo -and $eventoMasAntiguo.TimeCreated -gt (Get-Date).AddDays(-$DIAS_REVISION_EVENTOS)) {
    $estados += 'amarillo'
    $motivos += "El registro solo empieza el $(Formatear-Fecha $eventoMasAntiguo.TimeCreated): Windows se reinstaló o se borró el historial hace poco."
  }
  return @{ Titulo = "Errores de los últimos $DIAS_REVISION_EVENTOS días"; Estado = Obtener-PeorEstado $estados; Motivos = $motivos; Cuerpo = Nueva-Tabla $filas }
}
