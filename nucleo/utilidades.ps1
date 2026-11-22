# Funciones comunes a todos los apartados

function Escapar-Texto($texto) {
  if ($null -eq $texto -or "$texto".Trim() -eq '') { return 'No disponible' }
  return [System.Net.WebUtility]::HtmlEncode("$texto".Trim())
}

function Formatear-Fecha($fecha) {
  if ($null -eq $fecha) { return $null }
  return ([datetime]$fecha).ToString($FORMATO_FECHA)
}

function Obtener-PeorEstado($estados) {
  $peor = 'gris'
  foreach ($estado in @($estados | Where-Object { $_ })) {
    if ($ORDEN_ESTADOS[$estado] -gt $ORDEN_ESTADOS[$peor]) { $peor = $estado }
  }
  return $peor
}

function Evaluar-Cantidad($cantidad, $limiteRevisar, $limiteMal) {
  if ($null -eq $cantidad) { return 'gris' }
  if ($cantidad -ge $limiteMal) { return 'rojo' }
  if ($cantidad -ge $limiteRevisar) { return 'amarillo' }
  return 'verde'
}

function Convertir-SiNo($valor) {
  if ($valor) { return 'Sí' }
  return 'No'
}

function Probar-EsAdministrador {
  $identidad = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal $identidad
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Ejecuta un apartado sin que un fallo detenga el informe
function Invocar-Seccion($titulo, [scriptblock]$bloque) {
  Write-Host "- $titulo"
  try {
    return & $bloque
  } catch {
    return @{
      Titulo  = $titulo
      Estado  = 'gris'
      Motivos = @("No se pudo leer esta información: $($_.Exception.Message)")
      Cuerpo  = ''
    }
  }
}
