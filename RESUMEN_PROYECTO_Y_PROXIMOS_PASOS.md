# 🛡️ Proyecto RTS Godot 4 — Resumen del Juego y Próximos Pasos

Este documento contiene el **resumen completo del diseño de arte, arquitectura 3D y estado actual del proyecto** para continuar en la próxima sesión.

---

## 📌 Estado Actual del Proyecto
- **Motor:** Godot 4 (Juego de Estrategia en Tiempo Real - RTS).
- **Mecánica Principal:** Evolución por Eras (de Prehistoria a eras avanzadas), recolección de recursos, economía de chozas y combate táctico.
- **Enfoque Artístico:** Coherencia fotorrealista rústica e histórica de la Era Inicial.

---

## 📂 Organización de la Carpeta de Imágenes

Todas las imágenes generadas se encuentran organizadas en:
`C:\Users\Facturador\Documents\PARRA 24\proyecto de juego\IMAGENES\EDAD PREHISTORICA\`

### 📋 Estructura de carpetas:
1. **`ANIMALES/`**: Contiene la lámina de los 6 animales prehistóricos (Mamut, Ciervo, Jabalí, Dientes de Sable, Lobo y Oso de las Cavernas).
2. **`ARMAS/`**: Contiene la lámina de las 4 armas de combate (Mazo de Madera, Roca de Puño, Honda y Lanza de Sílex).
3. **`CESTAS DE MATERIALES/`**: Contiene los 4 fardos rústicos para la espalda del aldeano (Carne de Caza, Piedra, Hierro y Oro).
4. **`MINAS/`**: Contiene las canteras y vetas rocosas naturales del terreno.
5. **`CASAS DE CONSTRUIR/` y `RESTO DE CASAS/`**: Chozas cónicas rústicas de ramas, barro y paja con hilera de piedras en la tierra.
6. **`PERSONAJES/`**: Colección de pruebas de personajes.

---

## 🧩 Arquitectura 3D Modular (3 Personajes Base)

Para optimizar memoria y acelerar el desarrollo en Godot 4, el juego utiliza **3 Modelos 3D Base**:

1. 🧍‍♂️ **Aldeano Hombre Base:** Cabello largo, barba natural, túnica rústica de cuero atada con cordón (sin hebillas de metal), manos vacías en T-Pose.
2. 🧍‍♀️ **Aldeana Mujer Base:** Cabello largo suelto, túnica de cuero rústica, **completamente descalza**, manos vacías en T-Pose.
3. ⚔️ **Guerrero Militar Base:** Cuerpo musculoso, túnica rústica de combate, manos vacías en T-Pose.

### 🎒 Sistema de Props Adjuntables en Godot (`BoneAttachment3D`):
- **Herramientas en Mano (`RightHandAttachment`):** Hacha de Piedra (talar), Pico de Piedra (minar), Maza de Piedra (construir), Lanza de Caza (cazar).
- **Armas en Mano (`RightHandAttachment`):** Mazo (Clubman), Roca de Puño (Brawler), Honda (Rock Thrower), Lanza (Spearman).
- **Recursos en Espalda (`BackAttachment`):** Atado de madera, cesta de carne, saco de piedra, saco de hierro, saco de oro.

---

## 📋 Lista de Prompts Optimizados para Bing (< 480 Caracteres)

### 🧍‍♂️ Aldeano Hombre Base
```text
Full body 3D render of an ancient tribal male villager with long hair and full beard. Simple rustic pelt tunic tied with leather cord, rawhide foot wraps, NO metal buckles. Bare open hands, T-pose, isolated light gray studio background, photorealistic 3D game asset.
```

### 🧍‍♀️ Aldeana Mujer Base (Descalza + Pelo Suelto)
```text
Full body 3D render of an ancient tribal female villager with long loose natural hair, NO braids. Simple rustic pelt dress tunic tied with hide cord, NO metal buckles, BAREFOOT with bare feet, NO shoes. Bare open hands, T-pose, isolated light gray studio background, photorealistic 3D game asset.
```

### ⚔️ Guerrero Militar Base
```text
Full body 3D render of a muscular ancient tribal warrior with long hair and full beard. Rugged rawhide warrior tunic tied with leather cord, hide arm wraps, NO metal buckles. Bare open hands, T-pose, isolated light gray studio background, photorealistic 3D game asset.
```

### ⚔️ Colección de Armas (4 Armas en una imagen)
```text
Isometric 3D game asset render sheet showing four ancient tribal weapons side-by-side on light gray background: 1. Heavy wooden war club. 2. Sharp fist rock knuckle. 3. Smooth throwing stone with leather sling. 4. Flint-tipped wooden spear. All weapons share matching primitive rustic prehistoric style, clean spacing between items, isolated studio lighting, high detail 3D render.
```

### 🎒 Cargas de Recursos de Espalda (4 Cargas en una imagen)
```text
Isometric 3D game asset render sheet of four primitive resource carrying packs on light gray background: 1. Food pack: Woven basket carrying hunted raw meat, securely covered. 2. Stone pack: Rawhide thong thongs bundle filled with gray stones. 3. Iron pack: Dark hide pack filled with iron ore rocks. 4. Gold pack: Crude hide pouch filled with gold ore. All packs share rustic Stone Age style, clean spacing, high detail 3D render.
```

### 🐾 Fauna Prehistórica (6 Animales en una imagen)
```text
Isometric 3D game asset render sheet of six prehistoric animals side-by-side on light gray background: 1. Mammoth elephant. 2. Prehistoric deer. 3. Wild boar. 4. Saber-toothed tiger. 5. Dire wolf. 6. Cave bear. All creatures share matching realistic prehistoric wildlife style, clean spacing between animals, isolated studio lighting, high detail 3D render.
```

### ⛏️ Canteras y Minas del Terreno (4 Nodos en una imagen)
```text
Isometric 3D game asset render sheet of four natural resource quarry nodes on light gray background: 1. Stone quarry granite rock outcrop node. 2. Dark metallic iron ore deposit rock node with rust accents. 3. Exposed shiny yellow gold ore vein rock node. 4. Wild lush berry bush food node. All nodes share matching realistic prehistoric terrain style, clean spacing between items, isolated studio lighting, high detail 3D render.
```

### 🛖 Chozas Desordenadas Primitivas (4 Chozas en una imagen)
```text
Isometric 3D game asset render sheet of four messy rustic stone age conical huts on light gray background: 1. Settlement hut: Messy raw branch and bark cone shelter with campfire on bare dirt. 2. Capitol hut: Large chief cone shelter with animal pelts on dirt. 3. House: Small messy branch hut. 4. Barracks: Raw log fence compound with weapon racks. Organic asymmetrical prehistoric style, unorganized raw wood, bare dirt, NO stone walls, 3D render.
```

---

## 🚀 Próximos Pasos para la Siguiente Sesión

1. **Recorte e Importación a 3D:**
   - Tomar los recortes de las imágenes de las carpetas.
   - Convertirlos a formato **`.GLB`** en [TripoSR](https://huggingface.co/spaces/stabilityai/TripoSR) o **Rodin 3D**.
   - Colocarlos dentro de la carpeta `resources/models/` de Godot.

2. **Ensamblado en Godot 4:**
   - Configurar los nodos `BoneAttachment3D` en la escena del Aldeano y Guerrero.
   - Programar la lógica de recolección de madera/comida/piedra/oro y construcción de chozas en GDScript.

---
*Archivo guardado automáticamente en `res://RESUMEN_PROYECTO_Y_PROXIMOS_PASOS.md`.*
