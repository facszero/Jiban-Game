# 0.2 — primera pasada visual

Se conservan combate, daño, colisiones, terminales y recorrido de 0.1. La mejora se concentra en modelos procedurales de pocos polígonos y ambientación.

- Jiban: cúpula del casco, visor, respirador, sensores, placas, hombreras redondeadas y rodillas.
- Masques: traje oscuro, marca circular frontal y máscara clara en U; extremidades articuladas.
- Chamelenoid: primera aproximación del enemigo pesado a partir de una captura del episodio 1. Cresta, anillos claros alrededor de ojos, hombros rojizos y apéndices verdes. Las proporciones del cuerpo no visibles en la referencia son interpretación provisional. Conserva la IA cuerpo a cuerpo del prototipo; sus poderes de la serie aún no están implementados.
- Sector: paneles de servicio, tuberías superiores, líneas de seguridad, jaulas de contención con siluetas y letreros.
- Audio: zumbido industrial sintetizado, original, a volumen bajo; se pausa con el juego.

## Referencias consultadas

- Masques: https://metalheroes.fandom.com/wiki/Masques (imagen Masquejiban).
- Capturas de Jiban y Chamelenoid del episodio 1: https://ameblo.jp/redbeetle/entry-11492669667.html .
- Identificación del episodio y enemigo: archivo de la Biblioteca de Radiodifusión de Japón, https://www.bpcj.or.jp/program/detail/216165/ .

Las capturas se consultaron como referencia visual; no se incluyen en el juego. Los modelos siguen siendo aproximaciones simplificadas, no reproducciones terminadas de los trajes.

## Verificación

Importación y exportación Web con Godot 4.5.1; 23 comprobaciones funcionales y 3 de controles táctiles sin fallos. Pendiente medir rendimiento y revisar fidelidad visual en el Android del usuario. El navegador remoto utilizado en 0.1 no dispone de WebGL2.

## Próximo hito

Revisión visual por el usuario, ajustes de proporciones y rendimiento, luego navegación de enemigos, ataques diferenciados y ampliación del primer sector. No se considera completa la demo de 10–15 minutos.
