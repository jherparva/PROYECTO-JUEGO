# Estado del Proyecto RTS y Próximos Pasos

## Lo que hemos logrado hasta ahora:
1. **Configuración Base:** Tenemos un proyecto de Godot 4 configurado para un juego de estrategia en tiempo real (RTS) en 2D (vista top-down).
2. **Cámara y Controles:** La cámara se puede mover con el teclado o el ratón en los bordes. Existe un sistema para seleccionar unidades con un cuadro de selección (click izquierdo) y moverlas (click derecho).
3. **Máquina de Estados:** Las unidades tienen comportamientos programados a través de una Máquina de Estados (Idle, Move, Gather, Repair, Attack).
4. **Fondo y Terreno:** El mapa ahora tiene un fondo base de color verde (Polygon2D) sobre el cual las unidades pueden caminar. La "Niebla de Guerra" está desactivada temporalmente para facilitar las pruebas.
5. **Assets (Gráficos):**
   - Importamos un aldeano y un soldado generados por código (pixel art). 
   - Integramos con éxito partes del **Kenney Retro Fantasy Kit** (están guardados en `resources/sprites/buildings`, `resources/sprites/world` y los modelos 3D en `resources/models`).

## Tareas para la próxima vez (Continuar desde aquí):

### 1. Mejorar el Pixel Art (Quitar lo borroso/pixelado raro)
Como notaste que se ve pixelado/borroso, la próxima vez debemos ir a **Project Settings -> Rendering -> Textures** y cambiar el filtro por defecto a **"Nearest"**. Esto hará que el pixel art se vea nítido y perfecto.

### 2. Implementar Gráficos de Edificios
Tenemos imágenes como `town_center.png` y `house.png` (del pack de Kenney). Necesitamos asignarlos a nuestros nodos de edificios (`BuildingBase`) para poder ver las construcciones en el mapa en lugar de cuadros invisibles.

### 3. Configurar Animaciones Reales
Actualmente, el aldeano carga su sprite estático. El siguiente paso gráfico es usar "spritesheets" para que el aldeano mueva las piernas al caminar y mueva el hacha al talar madera.

### 4. Recolección y UI
Probar recolectar un recurso haciendo click derecho en un árbol (o en un barril de comida del pack de Kenney) y ver cómo los recursos aumentan en el HUD de la pantalla superior.

### 5. Colisiones y Pathfinding
Asegurarnos de que el aldeano no pueda caminar por encima de los edificios o el agua usando los obstáculos y el `NavigationRegion2D`.

---
*Nota: Para continuar trabajando, simplemente abre este proyecto en Godot y abre la escena `res://scenes/main.tscn`.*
