# Probar desde el navegador

El workflow **Build browser demo** exporta el juego desde `codex/prototype-sector-01`, ejecuta las pruebas y prepara el despliegue oficial de Pages. También conserva un ZIP `jiban-browser-demo` en sus artefactos.

## Activación única por el propietario

1. Abrir https://github.com/facszero/Jiban-Game/settings/pages.
2. En **Build and deployment → Source**, elegir **GitHub Actions**.
3. Volver al workflow **Build browser demo** en Actions y volver a ejecutar el trabajo de despliegue si falló antes de habilitar Pages.
4. Esperar al despliegue de Pages y usar el enlace mostrado por GitHub.

El repositorio es privado. GitHub Pages para repositorios privados requiere un plan compatible (por ejemplo, Pro); no cambiar la visibilidad del repositorio sin autorización. La página del juego normalmente es pública aunque el código fuente sea privado. Esta preparación no activa Pages ni cambia la visibilidad.

La conexión utilizada para editar código no administra Pages, y el navegador de trabajo no tiene sesión iniciada. Por eso la activación debe realizarla el propietario o completarse tras iniciar sesión.

## Uso

En PC: hacer clic dentro del juego para capturar el ratón; WASD y controles del README. Esc libera el ratón/abre pausa.

En Android: abrir en horizontal; botones de movimiento a la izquierda, arrastre sobre el centro/derecha para mirar, FUEGO/USAR/CARGA/SALTO y VISTA/PAUSA/LUZ. Los controles táctiles son iniciales y requieren prueba en el teléfono real.

WebGL 2 es necesario. Exportación sin hilos para evitar requerir cabeceras COOP/COEP en Pages. No se requiere instalar Godot para jugar en la página. No hay todavía guardado persistente.

## Validación de esta preparación

Las 23 comprobaciones del prototipo siguen pasando. Se agregaron tres comprobaciones de entrada táctil: pulsar dirección, soltar dirección y arrastrar la cámara. Son entradas simuladas en el motor, no una prueba en un Android físico.
