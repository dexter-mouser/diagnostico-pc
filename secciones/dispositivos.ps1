# Apartado: dispositivos con fallos y dispositivos esperados

function Obtener-DispositivosConError($dispositivos) {
  return @($dispositivos | Where-Object { $_.ConfigManagerErrorCode -and $_.ConfigManagerErrorCode -ne $CODIGO_DESCONECTADO })
}

function Buscar-Dispositivo($dispositivos, $regla) {
  return $dispositivos | Where-Object {
    $regla.Clases -contains $_.PNPClass -and $_.Name -match $regla.Nombre -and (-not $regla.Excluir -or $_.Name -notmatch $regla.Excluir)
  } | Select-Object -First 1
}

function Obtener-Dispositivos {
  $dispositivos = Obtener-ListaDispositivos
  $estados = @()
  $motivos = @()
  $filas = [ordered]@{}
  foreach ($nombre in $DISPOSITIVOS_ESPERADOS.Keys) {
    $regla = $DISPOSITIVOS_ESPERADOS[$nombre]
    $encontrado = Buscar-Dispositivo $dispositivos $regla
    if ($encontrado) {
      $filas[$nombre] = $encontrado.Name
    } elseif ($regla.EsNecesario) {
      $filas[$nombre] = 'No detectado'
      $estados += 'amarillo'
      $motivos += "${nombre}: no se detecta. Puede estar desactivado en la BIOS o averiado."
    } else {
      $filas[$nombre] = 'No tiene'
    }
  }
  $conError = Obtener-DispositivosConError $dispositivos
  $cuerpo = "<h3>Dispositivos esperados</h3>$(Nueva-Tabla $filas)"
  if ($conError.Count -gt 0) {
    $estados += 'amarillo'
    $motivos += "$($conError.Count) dispositivo(s) con error en el Administrador de dispositivos."
    $filasError = [ordered]@{}
    foreach ($dispositivo in $conError) {
      $codigo = [int]$dispositivo.ConfigManagerErrorCode
      $descripcion = $CODIGOS_ERROR_DISPOSITIVO[$codigo]
      if (-not $descripcion) { $descripcion = 'Error' }
      $filasError["$($dispositivo.Name)"] = "$descripcion (código $codigo)"
    }
    $cuerpo += "<h3>Dispositivos con error</h3>$(Nueva-Tabla $filasError)"
  } else {
    $estados += 'verde'
  }
  return @{ Titulo = 'Dispositivos'; Estado = Obtener-PeorEstado $estados; Motivos = $motivos; Cuerpo = $cuerpo }
}
