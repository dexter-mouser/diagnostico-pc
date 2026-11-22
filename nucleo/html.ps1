# Piezas de HTML y armado del informe

function Nuevo-Indicador($estado) {
  if (-not $estado) { return '' }
  return "<span class=`"indicador $estado`">$($TEXTO_ESTADOS[$estado])</span>"
}

function Nueva-Tabla($filas) {
  $html = '<table><tbody>'
  foreach ($clave in $filas.Keys) {
    $html += "<tr><th scope=`"row`">$(Escapar-Texto $clave)</th><td>$(Escapar-Texto $filas[$clave])</td></tr>"
  }
  return $html + '</tbody></table>'
}

function Nueva-Lista($puntos, $clase = 'motivos') {
  $puntos = @($puntos | Where-Object { $_ })
  if ($puntos.Count -eq 0) { return '' }
  $html = "<ul class=`"$clase`">"
  foreach ($punto in $puntos) { $html += "<li>$(Escapar-Texto $punto)</li>" }
  return $html + '</ul>'
}

function Nueva-Seccion($seccion) {
  $indicador = Nuevo-Indicador $seccion.Estado
  $motivos = Nueva-Lista $seccion.Motivos
  return "<section><h2>$(Escapar-Texto $seccion.Titulo) $indicador</h2>$motivos$($seccion.Cuerpo)</section>"
}

# Puntuación global: resta puntos por cada apartado en amarillo o rojo
function Calcular-Puntuacion($secciones) {
  $puntos = $PUNTOS_MAXIMOS
  foreach ($seccion in $secciones) {
    $estado = "$($seccion.Estado)"
    if ($PENALIZACION_PUNTOS.ContainsKey($estado)) { $puntos -= $PENALIZACION_PUNTOS[$estado] }
  }
  return [math]::Max(0, $puntos)
}

function Evaluar-Puntuacion($puntos) {
  if ($puntos -ge $PUNTUACION_BIEN) { return 'verde' }
  if ($puntos -ge $PUNTUACION_REVISAR) { return 'amarillo' }
  return 'rojo'
}

function Nuevo-Resumen($secciones, $esAdministrador) {
  $puntos = Calcular-Puntuacion $secciones
  $estadoPuntos = Evaluar-Puntuacion $puntos
  $html = '<section class="resumen"><h2>Resumen</h2>'
  $html += "<p class=`"puntuacion $estadoPuntos`"><strong>$puntos</strong> / $PUNTOS_MAXIMOS $(Nuevo-Indicador $estadoPuntos)</p>"
  if (-not $esAdministrador) {
    $html += '<p class="aviso">No se ejecutó como administrador: faltan datos de los discos y de BitLocker. Usa ejecutar.bat.</p>'
  }
  $html += '<ul>'
  foreach ($seccion in $secciones | Where-Object { $_.Estado }) {
    $html += "<li>$(Nuevo-Indicador $seccion.Estado) $(Escapar-Texto $seccion.Titulo)</li>"
  }
  return $html + '</ul></section>'
}

function Nueva-Pagina($secciones, $esAdministrador) {
  $plantilla = Get-Content (Join-Path $RAIZ 'plantilla.html') -Raw -Encoding UTF8
  $cuerpo = Nuevo-Resumen $secciones $esAdministrador
  foreach ($seccion in $secciones) { $cuerpo += Nueva-Seccion $seccion }
  $fecha = (Get-Date).ToString("$FORMATO_FECHA HH:mm")
  return $plantilla.Replace('{{FECHA}}', $fecha).Replace('{{EQUIPO}}', (Escapar-Texto $env:COMPUTERNAME)).Replace('{{CONTENIDO}}', $cuerpo)
}
