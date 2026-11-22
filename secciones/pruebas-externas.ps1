# Apartado fijo: programas recomendados para pruebas largas

function Obtener-PruebasExternas {
  $cuerpo = @'
<ul>
<li><a href="https://crystalmark.info/" target="_blank" rel="noopener">CrystalDiskInfo</a>: segunda opinión sobre la salud del disco.</li>
<li><a href="https://www.hwinfo.com/" target="_blank" rel="noopener">HWiNFO</a>: temperaturas y sensores en tiempo real.</li>
<li><a href="https://www.ocbase.com/" target="_blank" rel="noopener">OCCT</a>: prueba de estrés de 15 minutos. El procesador no debería pasar de 95 °C ni el equipo apagarse.</li>
<li><a href="https://www.memtest86.com/" target="_blank" rel="noopener">MemTest86</a>: prueba de la RAM arrancando desde una USB.</li>
</ul>
'@
  return @{ Titulo = 'Pruebas recomendadas con otros programas'; Estado = $null; Motivos = @(); Cuerpo = $cuerpo }
}
