# Apartado fijo: lista de revisión manual y prueba de pantalla

function Obtener-RevisionManual {
  $grupos = [ordered]@{
    'Pantalla'           = @('Sin píxeles muertos ni manchas (usa los botones de color)', 'Brillo uniforme y sin parpadeo', 'Bisagras firmes, la pantalla no cae sola')
    'Entrada'            = @('Todas las teclas funcionan (pruébalas en el Bloc de notas)', 'Touchpad y sus clics', 'Retroiluminación del teclado, si la tiene')
    'Conexiones'         = @('Todos los puertos USB', 'HDMI u otra salida de vídeo', 'Conector de auriculares', 'Carga con su cargador y el indicador se enciende')
    'Red y multimedia'   = @('Wi-Fi y Bluetooth', 'Cámara', 'Micrófono', 'Altavoces sin distorsión')
    'Carcasa'            = @('Sin grietas ni golpes', 'Todos los tornillos (si faltan, lo han abierto)', 'El ventilador no hace ruidos raros bajo carga')
    'Cuentas y bloqueos' = @('La BIOS no pide contraseña', 'No hay cuentas del dueño anterior', 'BitLocker desactivado o con la clave de recuperación entregada')
  }
  $cuerpo = '<div class="revision">'
  $numero = 0
  foreach ($grupo in $grupos.Keys) {
    $cuerpo += "<fieldset><legend>$(Escapar-Texto $grupo)</legend>"
    foreach ($punto in $grupos[$grupo]) {
      $numero++
      $cuerpo += "<label for=`"punto-$numero`"><input type=`"checkbox`" id=`"punto-$numero`"> $(Escapar-Texto $punto)</label>"
    }
    $cuerpo += '</fieldset>'
  }
  $cuerpo += '</div><h3>Prueba de pantalla</h3><p>Pulsa un color, revisa toda la pantalla y sal con un clic o con Esc.</p><div class="colores">'
  foreach ($color in @(@('Blanco', '#ffffff'), @('Negro', '#000000'), @('Rojo', '#ff0000'), @('Verde', '#00ff00'), @('Azul', '#0000ff'))) {
    $cuerpo += "<button type=`"button`" data-color=`"$($color[1])`">$($color[0])</button>"
  }
  return @{ Titulo = 'Revisión manual'; Estado = $null; Motivos = @(); Cuerpo = $cuerpo + '</div>' }
}
