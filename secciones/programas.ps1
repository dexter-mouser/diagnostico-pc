# Apartado: programas de acceso remoto, arranque e instalados

function Obtener-ProgramasInstalados {
  $rutas = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
  )
  return @(Get-ItemProperty $rutas -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -and -not $_.SystemComponent } |
    Sort-Object DisplayName -Unique)
}

# Busca acceso remoto en programas instalados, servicios y procesos (incluye versiones portables)
function Buscar-AccesoRemoto($programas) {
  $encontrados = @()
  $encontrados += $programas | Where-Object { $_.DisplayName -match $PATRON_ACCESO_REMOTO } | ForEach-Object { $_.DisplayName }
  $encontrados += Get-CimInstance Win32_Service | Where-Object { "$($_.Name) $($_.DisplayName)" -match $PATRON_ACCESO_REMOTO } | ForEach-Object { "Servicio: $($_.DisplayName)" }
  $encontrados += Get-Process | Where-Object { $_.ProcessName -match $PATRON_ACCESO_REMOTO } | ForEach-Object { "En ejecución: $($_.ProcessName)" }
  return @($encontrados | Sort-Object -Unique)
}

function Nueva-ListaProgramas($programas) {
  $html = "<details><summary>Ver los $($programas.Count) programas instalados</summary><ul class=`"lista-larga`">"
  foreach ($programa in $programas) {
    $editor = $(if ($programa.Publisher) { " · $(Escapar-Texto $programa.Publisher)" } else { '' })
    $html += "<li>$(Escapar-Texto $programa.DisplayName)$editor</li>"
  }
  return $html + '</ul></details>'
}

function Obtener-Programas {
  $programas = Obtener-ProgramasInstalados
  $accesoRemoto = Buscar-AccesoRemoto $programas
  $arranque = @(Get-CimInstance Win32_StartupCommand | Sort-Object Name)
  $estados = @('verde')
  $motivos = @()
  if ($accesoRemoto.Count -gt 0) {
    $estados += 'amarillo'
    $motivos += 'Hay programas de acceso remoto: el dueño anterior podría conectarse al equipo. Desinstálalos o reinstala Windows.'
  }
  $cuerpo = '<h3>Acceso remoto</h3>'
  if ($accesoRemoto.Count -gt 0) { $cuerpo += Nueva-Lista $accesoRemoto 'lista-larga' } else { $cuerpo += '<p>No se encontraron programas de acceso remoto conocidos.</p>' }
  $cuerpo += '<h3>Programas que arrancan con Windows</h3>'
  if ($arranque.Count -gt 0) { $cuerpo += Nueva-Lista ($arranque | ForEach-Object { $_.Name }) 'lista-larga' } else { $cuerpo += '<p>Ninguno.</p>' }
  $cuerpo += Nueva-ListaProgramas $programas
  $cuerpo += '<p>Lo más seguro después de comprarlo es reinstalar Windows desde cero.</p>'
  return @{ Titulo = 'Programas'; Estado = Obtener-PeorEstado $estados; Motivos = $motivos; Cuerpo = $cuerpo }
}
