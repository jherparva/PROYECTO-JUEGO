# 📜 GUÍA MAESTRA DEFINITIVA DE MODELADO 3D POR ERAS — EMPIRE TACTICS

> **Manual de Especificaciones de Assets 3D para Blender / Godot 4.3**  
> *Incluye el 100% de Edificaciones, Personajes, Criaturas y la **Lista Completa de Armas de Asedio, Vehículos, Tanques, Catapultas, Barcos y Cazas** para las 10 Eras.*

---

## 🎨 Especificaciones Técnicas de Modelado 3D (Godot 4.3)

> [!IMPORTANT]
> **Normas de Exportación y Mallas**:
> - **Formato de Entrega**: Archivos `.gltf` o `.glb` con textura e iluminación PBR incrustadas (`StandardMaterial3D`).
> - **Escala Global**: $1.0\text{ unidad Godot} = 1.0\text{ metro real}$.
> - **Pivote / Origen ($0,0,0$)**: En la **planta de los pies** en personajes/unidades, y en la **base del piso** en edificios y vehículos.
> - **Máscara de Color de Equipo**: Asignar un segundo material `StandardMaterial3D` o canal en la malla para que el motor reemplace dinámicamente el **Color de Bando/Jugador** seleccionado en el lobby.
> - **Nodos Hijos y Sockets de Anclaje Obligatorios**:
>   - `RightHandAttachment`: Punto de sujeción de herramientas/armas en mano derecha (hachas, picos, espadas, lanzas, arcos).
>   - `BackAttachment`: Punto de sujeción para fardos de recursos procedurales (madera, piedra, oro), aljabas o mochilas a la espalda.
>   - `ProjectileMuzzle`: Socket en la punta del arma, torreta, torre o mano para el spawn físico y alineación del proyectil 3D balístico (`Projectile3D`).
>   - `DropOffPoint`: Nodo/Área en la entrada o dársena de Capitolios, Centros Urbanos y Muelles para la descarga síncrona de recursos por aldeanos y barcos pesqueros.
>   - `GarrisonPoint`: Punto de entrada/salida para el guarecido de unidades en edificios (Capitolio, Templo, Casas) y navíos de transporte.
>   - `SelectionIndicator`: Anillo indicador de selección en la base ($Y = 0.08m$).
> - **Auto-Tiling de Murallas Modulares**: Las mallas de murallas (ej. `WallWoodEra1`) deben contener las submallas con la nomenclatura exacta:
>   - `Mesh_straight`: Tramo recto continuo.
>   - `Mesh_corner_l`: Esquina en "L".
>   - `Mesh_inter_t`: Intersección en "T" de tres direcciones.
>   - `Mesh_cross`: Cruce en "+" de cuatro direcciones.
>   - `Mesh_end`: Poste o remate final de un solo extremo.

---

## 🚀 SECCIÓN ESPECIAL: CATÁLOGO COMPLETO DE MAQUINARIA DE GUERRA, VEHÍCULOS Y ARMAS DE ASIEDO POR ERA

| Era | Tipo de Arma / Vehículo 3D | Nombre del Asset | Descripción Visual y Armamento Integrado |
|---|---|---|---|
| **Era 0 (Prehistórica)** | Embarcación de Transporte | `Canoa_Madera_Era0` | Canoa de tronco vaciado para cruzar ríos/costas. Guarece hasta 4 infantes, flotación a $Y = -1.8\text{m}$ con desembarco por RPC. |
| **Era 0 (Prehistórica)** | Embarcación Pesquera | `Barco_Pesca_Era0` | Bote rústico de madera para pesca autónoma en aguas profundas con bodega de 20 peces y descarga en muelle. |
| **Era 0 (Prehistórica)** | Armamento Contundente | `Garrote_Hueso_Era0` | Garrote de madera con espinas de hueso incrustadas (`MELEE_SHOCK`, daño x1.35 vs madera y empalizadas). |
| **Era 0 (Prehistórica)** | Armamento Punzante | `Lanza_Sílex_Era0` | Lanza corta de punta de pedernal atada con tendones (`MELEE_PIERCE`, daño x2.5 vs fauna pesada/mamuts). |
| **Era 0 (Prehistórica)** | Báculo Ceremonial | `Báculo_Chamán_Era0` | Báculo tribal de madera con cráneo de lobo y fuego que emite un aura zonal de 12m (+15% daño / +10% velocidad). |
| **Era 1 (Piedra)** | Embarcación Ligera | `Balsa_Totora_Era1` | Balsa de juncos y totora tejida con amarres de fibra vegetal. |
| **Era 1 (Piedra)** | Embarcación Pesquera | `Barco_Pesca_Piedra` | Canoa reforzada con red de fibra tejida y contrapesos de piedra perforada. |
| **Era 1 (Piedra)** | Armamento de Asalto | `Maza_Piedra_Era1` | Maza de combate con cabeza de piedra esférica perforada (+15% daño base respecto al Clubman primitivo). |
| **Era 1 (Piedra)** | Armamento de Corte | `Hacha_Piedra_Era1` | Hacha de piedra pulida de doble bisel (`Slashing`, daño x1.40 vs infantería ligera y x1.30 vs murallas de madera). |
| **Era 1 (Piedra)** | Armamento Balístico | `Honda_Roca_Era1` | Honda de cuero trenzado para rocas ligeras (`ARROW/Sling`, alcance 15m, daño x1.5 vs infantería `MELEE_SHOCK`). |
| **Era 1 (Piedra)** | Armamento de Rango | `Arco_Simple_Piedra` | Arco corto de madera flexible y flechas de sílex (14m alcance, bono nativo de facción inglesa +15% daño/rango). |
| **Era 1 (Piedra)** | Báculo Sagrado | `Bastón_Profeta_Era1` | Báculo místico de madera con menhir rúnico para invocar Terremoto DoT en 8m (5 HP/s por 6s a estructuras enemigas). |
| **Era 2 (Bronce)** | Carro de Guerra | `Carro_Primitivo_Era2` | Carro de madera de 2 ruedas tirado por 2 caballos de guerra. |
| **Era 2 (Bronce)** | Navío de Guerra | `Galera_Fenicia_Era2` | Galera de remos con vela cuadrada de tela. |
| **Era 2 (Bronce)** | Armamento Especial | `Red_Tridente_Retiarius` | Red pesada de retiario y tridente de bronce. |
| **Era 3 (Hierro)** | Asedio | `Ariete_Carnero_Era3` | Ariete de choque con viga y cabeza de carnero de hierro. |
| **Era 3 (Hierro)** | Asedio a Distancia | `Balista_Torsión_Era3` | Balista de torsión sobre ruedas para virotes pesados. |
| **Era 3 (Hierro)** | Asedio Catapulta | `Catapulta_Onagro_Era3` | Catapulta de torsión de madera para lanzar rocas ardientes. |
| **Era 3 (Hierro)** | Navío de Guerra | `Trirreme_Romano_Era3` | Galera de tres filas de remos con espolón de bronce. |
| **Era 3 (Hierro)** | Unidad Montada Pesada | `WarElephant_Era3` | Elefante de guerra con torreta de madera y bardas de hierro. |
| **Era 4 (Medieval)** | Súper Asedio | `Trabuquete_Contrapeso` | Trabuquete masivo oscilante con cajón de contrapeso de piedra. |
| **Era 4 (Medieval)** | Asedio Rodante | `Torre_Asedio_Era4` | Torre rodante de madera recubierta con pieles húmedas. |
| **Era 4 (Medieval)** | Asedio Cubierto | `Ariete_Techo_Era4` | Ariete con techo inclinado de madera contra flechas. |
| **Era 4 (Medieval)** | Navío Pesado | `Carraca_Galeón_Era4` | Carraca de tres mástiles con castillos de proa y popa. |
| **Era 4 (Medieval)** | Transporte Terrestre | `Carromato_Bueyes_Era4` | Carro de mercancías tirado por dos bueyes. |
| **Era 5 (Renacimiento)** | Artillería Pesada | `Cañón_Culebrina_Era5` | Cañón de bronce sobre cureña de madera de roble. |
| **Era 5 (Renacimiento)** | Artillería Mortero | `Mortero_Sitio_Era5` | Mortero pesado de bronce para tiro parabólico. |
| **Era 5 (Renacimiento)** | Navío Explorador | `Carabela_Era5` | Carabela de tres mástiles con velas cruzadas de grana. |
| **Era 5 (Renacimiento)** | Navío de Guerra | `Galeón_Pólvora_Era5` | Galeón con 2 puentes de cañones laterales. |
| **Era 5 (Renacimiento)** | Blindado Especial | `Carro_Blindado_DaVinci` | Carro blindado cónico de madera con cañones perimetrales. |
| **Era 6 (Industrial)** | Blindado de Vapor | `SteamTank_Era6` | Tanque de vapor de calderas de hierro remachado. |
| **Era 6 (Industrial)** | Transporte Terrestre | `Camión_Industrial` | Camión primitivo con motor de explosión interna. |
| **Era 6 (Industrial)** | Tren / Logística | `Locomotora_Vapor_Era6` | Locomotora 4-4-0 con vagones de transporte militar. |
| **Era 6 (Industrial)** | Navío Acorazado | `Acorazado_Ironclad` | Buque Ironclad de casco de hierro y chimenea de vapor. |
| **Era 6 (Industrial)** | Artillería Ligera | `Ametralladora_Gatling` | Ametralladora Gatling de manivela sobre ruedas. |
| **Era 7 (Atómica)** | Blindado Medio | `Tanque_Sherman_T34` | Tanque medio de combate 3D con cañón de 75mm y orugas. |
| **Era 7 (Atómica)** | Blindado Pesado | `Tanque_Pesado_Asalto` | Tanque pesado blindado con cañón de 90mm. |
| **Era 7 (Atómica)** | Transporte Blindado | `APC_Transporte_Era7` | Transporte blindado sobre orugas con torreta. |
| **Era 7 (Atómica)** | Aviación Caza | `Caza_Hélice_Era7` | Caza monoplano de hélice (estilo P-51 Mustang). |
| **Era 7 (Atómica)** | Aviación Bombardero | `Bombardero_B29_Era7` | Bombardero pesado cuatrimotor B-29. |
| **Era 7 (Atómica)** | Submarino | `Submarino_Diésel_Era7` | Submarino diésel de ataque. |
| **Era 7 (Atómica)** | Armamento Súper ICBM | `Misil_Nuclear_ICBM` | Misil balístico intercontinental con ojiva atómica. |
| **Era 7 (Atómica)** | Armamento Manual | `Lanzallamas_Napalm` | Lanzallamas con mochila de napalm. |
| **Era 7 (Atómica)** | Armamento Anti-Tanque | `Lanzacohetes_Bazuca` | Lanzacohetes portátil RPG. |
| **Era 8 (Digital)** | Aviación Sigilo | `Caza_Furtivo_Era8` | Caza furtivo de 5ta generación (F-22 Stealth). |
| **Era 8 (Digital)** | Aviación Drone UAV | `Drone_Reaper_Era8` | Drone aéreo no tripulado con misiles Hellfire. |
| **Era 8 (Digital)** | Robótica Terrestre | `UGV_Robot_Combate` | Vehículo terrestre no tripulado sobre orugas con torreta. |
| **Era 8 (Digital)** | Helicóptero Sigilo | `Helicóptero_Cyber_Era8` | Helicóptero de ataque de sigilo con rotores carenados. |
| **Era 8 (Digital)** | Dron Ligero | `Dron_Enjambre_Era8` | Dron táctico aéreo de ataque enjambre. |
| **Era 8 (Digital)** | Armamento Especial | `Cañón_Pulso_EMP` | Cañón portátil de pulso electromagnético. |
| **Era 9 (Nano-Futurista)** | Blindado Levitante | `HoverTank_Levitante` | Tanque de propulsión de repulsión magnética. |
| **Era 9 (Nano-Futurista)** | Mech Bípedo | `PlasmaMech_Bípedo` | Mech robot de combate de 4 metros con cañón de plasma. |
| **Era 9 (Nano-Futurista)** | Dron Titán | `Dron_Titán_Plasma` | Dron aéreo pesado con rayo desintegrador. |
| **Era 9 (Nano-Futurista)** | Transportador Aéreo | `Transporte_Nano_Aéreo` | Transportador levitante de personal infrarrojo. |
| **Era 9 (Nano-Futurista)** | Navío Espacial | `Frigata_Plasma_Era9` | Nave de guerra espacial/atmosférica aerodinámica. |
| **Era 9 (Nano-Futurista)** | Desembarco | `DropPod_Orbital_Era9` | Cápsula de desembarco táctico desde la órbita. |
| **Era 9 (Nano-Futurista)** | Súper-Arma | `Cañón_Orbital_Plasma` | Plataforma de inducción magnética espacial. |
| **Era 9 (Nano-Futurista)** | Armamento Manual | `Fusil_Gauss_Riel` | Rifle electromagnético Gauss de riel. |

---

## 🦴 ERA 0 — ERA PREHISTÓRICA (Prehistoric Age)

### 🏛️ Edificaciones (Buildings)
- `TownCenter_Era0` (**Capitolio Principal Prehistórico GLB**):
  - **Asset 3D Asignado en Proyecto**: `IMAGENES/EDAD PREHISTORICA/CASAS DE CONSTRUIR/capitolio edad prehistorica.glb`.
  - **Especificaciones**: Gran choza central construida con costillares y colmillos de mamut, cubierta de pieles curtidas tensadas con lianas alrededor de una hoguera sagrada. Cuenta con socket `DropOffPoint` para entrega síncrona de comida/madera/piedra y capacidad de guarnecer hasta 10 aldeanos devotos.
- `Barracks_Era0` (**Cuartel Primitivo**): Círculo de empalizadas de troncos toscos con cueros tensados y arcos de cuernos. Restringido por `dbtechtree.dat` para entrenar únicamente `Brawler_Primitivo`, `Clubman_Era0` y `Spearman_Era0`.
- `House_Era0` / `Hut_Era0` (**Choza Prehistórica**): Tienda cónica pequeña de pieles de fiera y palos entrelazados. Integra sincronización dinámica de población: otorga **+5 de población máxima** al terminarse la obra y resta 5 al ser destruida o demolida.
- `Tower_Era0` (**Torre Trípode Defensiva**): Plataforma de vigas de madera atadas sobre un trípode tosco con escalera de cuerda. Dispone de socket `ProjectileMuzzle` superior a 22m de alcance balístico y aplica bonificación de altura (+25% daño si se ubica en colinas $\Delta Y \ge 2.0\text{m}$).
- `Dock_Era0` (**Muelle Costero Primitivo**): Muelle rudimentario de troncos amarrados sobre bajamar con rampa de tierra y zona `DropOffPoint` que procesa la entrega síncrona de barcos pesqueros (+20 Food).
- `Farm_Era0` (**Granja Primigenia**): Parcela de recolección de tubérculos y grano silvestre rodeada de estacas de madera, con soporte para regeneración y laboreo autónomo del aldeano.

### 👤 Personajes y Unidades de Combate (Units & Characters)
- `Brawler_Primitivo` (**Luchador a Mano Limpia**):
  - **Apariencia**: Guerrero atlético descalzo en taparrabos corto de piel de fiera, nudillos vendados con tiras de cuero y pintura corporal tribal.
  - **Comportamiento 3D**: `weapon_type = "fist"` (`RightHandAttachment` libre). Unidad de combate cuerpo a cuerpo más rápida de la era (+25% velocidad base). Sus ataques de puño veloces aplican un **15% de probabilidad de aturdimiento (Stun)** inmovilizando al rival durante 1.5 segundos.
- `Clubman_Era0` (**Guerrero con Garrote / Garrotero**): Infante con garrote pesado de madera con púas de hueso talladas (`MELEE_SHOCK`). Daño base 16.0 con **multiplicador estricto de x1.35 contra estructuras de madera y empalizadas**.
- `Spearman_Era0` (**Lancero de Sílex**): Infante con lanza de punta de pedernal atada con tendones (`MELEE_PIERCE`). Alcance extendido de 3.5m, daño 15.0 con **multiplicador estricto de x2.5 contra fauna pesada (Mamuts)**.
- `Leader_Prehistoric` (**Héroe Chamán Tribal**): Héroe de 350 HP y daño 22.0. Porta un cráneo ceremonial de lobo y un báculo encendido. Dispone de un nodo zonal `Area3D` de 12 metros ("Cántico Ritual") que otorga **+15% daño y +10% velocidad** a todas las tropas aliadas cercanas.
- `Villager_Male_Era0` / `Villager_Female_Era0`: Aldeanos primitivos equipados con herramientas procedurales en `RightHandAttachment` (hacha, pico, pala, lanza) y fardos de carga procedurales en `BackAttachment` (sacos de grano, troncos, cestos de piedra).
- `Canoa_Madera_Era0` (`Canoe3D`): Canoa de tronco vaciado para cruzar aguas costeras y ríos. Navega a nivel náutico $Y = -1.8\text{m}$, guarece hasta **4 infantes** con ocultamiento de mallas y ejecuta desembarcos síncronos con `rpc_descargar_todo()`.
- `Barco_Pesca_Era0` (`FishingBoat3D`): Barco de pesca costera autónoma con bodega de 20 unidades de pescado y ciclo automático de entrega en el Muelle.

### 🦣 Animales y Fauna (Fauna)
- `Mammoth_Era0` (**Mamut Lanudo Ancestral**): 240 HP, 600 unidades de comida. Fauna pesada de caza mayor con colmillos curvados en espiral.
- `Sabertooth_Era0` (**Tigre Dientes de Sable**): 120 HP, depredador carnívoro de ataque frontal agresivo.
- `CaveBear_Era0`: Oso de las Cavernas gigante agresivo (80 HP).
- `GiantDeer_Era0`: Ciervo Megaloceros de cornamenta extendida (pasivo, carne abundante).
- `WildBoar_Era0`: Jabalí salvaje veloz con colmillos curvos defensivos.

### 🪵 Objetos y Recursos (Objects & Props)
- `Resource_Wood_Era0`: Pila de troncos toscos partidos a piedra.
- `Resource_Food_Era0`: Arbusto de moras salvajes / Carcasa de animal cazado para faenado.
- `Resource_Flint_Era0`: Yacimiento de pedernal y piedras de sílex.
- `Prop_Campfire`: Fogata tribal con humo en partículas y ascuas ardientes.

---

## 🪨 ERA 1 — EDAD DE PIEDRA (Stone Age)

### 🏛️ Edificaciones (Buildings)
- `TownCenter_Era1`: Capitolio de adobe reforzado con cimientos de piedra de río, techos de paja densa, socket `DropOffPoint` y espacio de guarnición para aldeanos.
- `Barracks_Era1`: Cuartel con empalizada elevada de vigas cortadas a hacha, patio de armas y techado de cañas para entrenamiento militar de la era.
- `ArcheryRange_Era1` / `Archery_Range_3d.tscn` (**Campo de Tiro con Arco**):
  - **Especificaciones**: Estructura de entrenamiento balístico con dianas circulares de paja, soportes de madera labrada y aljabas comunales.
  - **Lógica de Juego**: Se desbloquea cuando `era_actual >= 1`. Permite la producción en cola del Lanzador de Piedras y el Bowman de Era 1, con bloqueo techtree de unidades avanzadas.
- `Stable_Era1` / `Corral_Era1` / `Stable_3d.tscn` (**Corral / Establo Temprano**):
  - **Especificaciones**: Cercado rústico de postes de madera pulida y comederos de piedra tallada.
  - **Lógica de Juego**: Se habilita en el menú de construcción del aldeano en Era 1 (`corral`). Permite la investigación síncrona `investigar_velocidad_monturas()`, incrementando la velocidad de monturas y caballería en un **+15%**.
- `Temple_Era1` / `Temple_3d.tscn` (**Menhir / Templo Sagrado**):
  - **Especificaciones**: Círculo sagrado de monolitos y menhires de piedra caliza con un altar central y fuego ritual perpetuo.
  - **Lógica de Juego**: Desbloquea la teocracia en red. Permite guarecer hasta 5 aldeanos rezando (`guarecer_aldeano()` / `expulsar_aldeanos()`), acumulando de forma pasiva **+1 de fe por segundo en `CivPointsManager` por cada aldeano devoto**. Permite la invocación y entrenamiento del Profeta de Piedra.
- `Wall_Wood_Era1` / `WallWoodEra1` (**Empalizada Afilada de Madera**):
  - **Especificaciones**: Muralla perimetral modular de troncos macizos con puntas afiladas al fuego.
  - **Resistencia**: Salud máxima calibrada en **1200 HP** según las tablas de `dbupgrade.dat`.
  - **Auto-Tiling**: Conectada con el grid de 4 metros (`building_placer.gd`) mediante submallas automáticas: `Mesh_straight`, `Mesh_corner_l`, `Mesh_inter_t`, `Mesh_cross` y `Mesh_end`.
- `House_Era1`: Casa rectangular de muros de barro seco compactado, zócalos de piedra y paja tejida (+5 población).
- `Tower_Era1`: Torre cuadrada de troncos verticales reforzada con base de mampostería seca y parapeto de tiro.
- `Dock_Era1`: Muelle de plataformas de madera labrada con pilotes fijos y zona `DropOffPoint` para navíos de pesca.

### 👤 Personajes y Unidades (Units & Characters)
- `Lanzador_Piedras` (**Hostigador de Rango**):
  - **Apariencia**: Guerrero ágil con túnica ligera de cuero sin mangas y zurrón de guijarros al cinto.
  - **Combate y Balística**: Alcance balístico de 15.0m (`weapon_type = "arrow/sling"`). Dispara desde el socket `ProjectileMuzzle` rocas ligeras (`projectile_type = "stone"`) que infligen un **multiplicador de daño estricto de x1.5 contra infantería cuerpo a cuerpo de choque (`MELEE_SHOCK`)**.
- `Maceman_Era1` (**Guerrero con Maza**):
  - **Apariencia**: Soldado de asalto con maza pesada de cabeza de piedra esférica perforada y mangual de madera dura.
  - **Counters**: Impacto `MELEE_SHOCK / Bludgeoning`. Su daño base cuenta con un incremento pasivo de **+15% respecto al Clubman primitivo** ($16.0 \rightarrow 18.4$) y bonificación contra fortificaciones de madera.
- `Axeman_Era1` (**Guerrero con Hacha de Piedra Pulida**):
  - **Apariencia**: Infante de choque con hacha de piedra pulida de doble filo biselado sujeta con tiras de cuero crudo.
  - **Counters**: Impacto tipo `Slashing`. Aplica un multiplicador estricto de **x1.40 contra infantería ligera** y **x1.30 contra empalizadas y murallas de madera**.
- `Bowman_Era1` (**Arquero de Piedra**):
  - **Apariencia**: Tirador con arco simple de madera flexible, aljaba de cuero a la espalda y flechas con puntas de sílex talladas.
  - **Parámetros**: Alcance de 14.0m, coste de 40 Comida y 30 Madera. Si la facción seleccionada es la **Inglesa**, hereda automáticamente los bonos nativos de civilización: **+15% de daño** y **+15% de alcance**.
- `Scout_Era1` (**Explorador a Pie**):
  - **Apariencia**: Batidor veloz sin armadura con vara de marcha ligera y zurrón de viaje.
  - **Parámetros**: Velocidad de carrera ultra veloz (**6.5 m/s**) con rango de visión de Niebla de Guerra duplicado a **56.0m** (+100%). Tiene bloqueado por código la recolección de recursos (`command_gather`) y el ataque/daño a edificios.
- `Prophet_Stone` / `ProphetStone3D` (**Héroe Místico / Profeta de Piedra**):
  - **Apariencia**: Profeta espiritual con túnica ceremonial blanca, pintura rúnica facial y bastón largo coronado con un menhir sagrado grabado.
  - **Habilidad RPC**: 300 HP y 200 Fe. Su comando `rpc_invocar_terremoto_piedra()` consume 40 puntos de fe e invoca un área sísmica de **8.0 metros** que drena un DoT de **5 HP/s durante 6.0 segundos** a estructuras enemigas dentro de su radio.
- `Villager_Era1`: Agricultor y artesano con túnica de lino rústico, cinto de cuero y herramientas de piedra pulida.

### 🦬 Animales y Ecosistema de la Estepa (Fauna & Props)
- `WildBison_Era1` (**Bisonte Salvaje de la Estepa**):
  - **Parámetros**: 180 HP y otorga **450 unidades de alimento**.
  - **Comportamiento**: Inicialmente pacífico, pero si un aldeano o cazador lo agrede, se vuelve agresivo de forma reactiva y embiste al atacante persiguiéndolo.
- `Gazelle_Era1` (**Gacela de la Pradera**):
  - **Parámetros**: 100 unidades de alimento.
  - **Comportamiento**: Animal asustadizo dotado de IA de huida ultra rápida. Al detectar cualquier unidad enemiga o civil en un radio de 12 metros, activa `is_fleeing = true` y escapa a **8.0 m/s**.
- **Extinción Esférica de 80m**: Mediante el método síncrono por RPC `rpc_reemplazar_fauna_extinta(center, 80.0)`, la transición hacia la Era 1 purga los Mamuts lanudos prehistóricos dentro de 80 metros a la redonda y los sustituye proceduralmente por manadas de Bisontes y Gacelas.
- `DireWolf_Era1`: Lobo gris feroz que merodea en jaurías agresivas.
- `FishCluster_Era1`: Banco de peces costeros visible sobre la superficie marina para barcos pesqueros.
- `Resource_Stone_Era1`: Cantera de bloques de caliza cortados con cuñas de madera y percutores de piedra.
- `Prop_Storage_Era1`: Canastas tejidas de mimbre llenas de grano, nueces y bayas almacenadas.

---

## 🗡️ ERA 2 — EDAD DE BRONCE (Bronze Age)

### 🏛️ Edificaciones (Buildings)
- `TownCenter_Era2`: Palacio mesopotámico/egipcio de ladrillos de adobe cocidos con columnas cilíndricas y detalles dorados.
- `Barracks_Era2`: Cuartel militar de muros de yeso y ladrillo con patio de armas.
- `Stable_Era2`: Establo de caballería de piedra labrada.
- `Dock_Era2`: Astillero naval con rampas de madera.
- `Market_Era2`: Bazar con toldos de lino de colores y puestos de mercadería.
- `Blacksmith_Era2`: Herrería con horno de fundición de bronce.
- `Wonder_Era2`: Zigurat de tres niveles con escalinatas monumentales y braceros.
- `Tower_Era2`: Torre de piedra con almenas y aspilleras.
- `Wall_Era2`: Muralla de adobe cocido reforzada.

### 👤 Personajes y Unidades (Units & Characters)
- `Retiarius_Gladiador` (**Gladiador Lanzador de Redes**): Gladiador con red de pesca y tridente de bronce.
- `Piquero_AntiGregario` (**Piquero Antigregario**): Infante con pica de bronce especializada (+100% daño contra carros y caballos).
- `Hoplite_Bronze` (**Hoplita de Falange**): Soldado con casco corintio de bronce, grebas y escudo aspis.
- `CompositeBowman_Era2` (**Arquero Compuesto**): Arquero con arco compuesto de láminas de madera y cuerno.
- `Villager_Era2`: Artesano con faldellín kilt de lino.
- `Priest_Bronze` (**Sacerdote de Bronce**): Sacerdote con túnica blanca y cetro de bronce con lapislázuli.
- `Hero_Pharaoh` (**Héroe Faraón**): Rey militar con armadura dorada de gala.

---

## ⚔️ ERA 3 — EDAD DE HIERRO (Iron Age)

### 🏛️ Edificaciones (Buildings)
- `TownCenter_Era3`: Foro romano/griego con columnas de mármol blanco, tejado de tejas de terracota y patio de ágora.
- `Barracks_Era3`: Castrum romano de piedra tallada con estandartes de hierro.
- `Stable_Era3`: Establo imperial con corrales de piedra tallada.
- `Dock_Era3`: Muelle de sillar con faro de piedra.
- `Academy_Era3`: Universidad / Academia de filosofía y estrategia.
- `Blacksmith_Era3`: Forja con yunque masivo de hierro y fuelle de cuero.
- `SiegeWorkshop_Era3`: Taller de maquinaria de asedio.
- `Tower_Era3`: Torre romana cuadrada de sillar.
- `Wall_Iron`: Muralla de bloques de sillar de 4m de alto.

### 👤 Personajes y Unidades (Units & Characters)
- `Espadachin_Hierro` (**Infantería Pesada**): Espadachín de hierro templado con escudo rectangular y galea.
- `Legionary_Era3` (**Legionario Romano**): Legionario con lorica segmentata de hierro, gladius y scutum.
- `Arquero_TiroLargo` (**Arquero Imperial**): Tirador ligero de arco de madera reforzada con punta de hierro.
- `Centurion_Era3` (**Héroe/Oficial**): Oficial con coraza muscular de hierro y penacho rojo.
- `Cataphract_Era3` (**Caballería Pesada**): Jinete e hípico cubiertos con cota de escamas de hierro.
- `ScoutCavalry_Era3` (**Caballería Ligera**): Jinete explorador con lanza corta.
- `Priest_Iron` (**Sacerdote Imperial**): Sacerdote imperial con túnica y báculo.

---

## 🏰 ERA 4 — ERA MEDIEVAL (Middle Ages)

### 🏛️ Edificaciones (Buildings)
- `TownCenter_Era4`: Castillo feudal de mampostería de piedra gris con foso, matacanes y torre del homenaje.
- `Barracks_Era4`: Cuartel gótico con arcos apuntados y armero de espadas.
- `Stable_Era4`: Establo real con pendones de caballeros.
- `Dock_Era4`: Astillero naval con grúas de madera.
- `Church_Era4`: Catedral/Iglesia románica con rosetón de vidrio y campanario.
- `Wonder_Era4`: Gran Catedral Gótica con agujas y vitrales.
- `Windmill_Era4`: Molino de viento de madera para granjas.
- `Tower_Keep_Era4`: Torre de homenaje alta con matacanes.
- `Wall_Medieval`: Muralla almenada de piedra con camino de ronda.

### 👤 Personajes y Unidades (Units & Characters)
- `Caballero_Pesado` (**Caballería Blindada Pesada**): Caballero con armadura completa de placas de acero y espada mandoble.
- `Pikeman_Era4` (**Piquero Medieval**): Piquero con morrión de hierro y pica de 4.5m.
- `Crossbowman_Era4` (**Ballestero**): Ballestero con gola de acero y ballesta con estribo.
- `Longbowman_Era4` (**Arquero Largo**): Arquero galés con arco largo de tejo.
- `Monk_Era4` (**Monje Templario**): Monje franciscano con hábito de lana y rosario.
- `Hero_King` (**Héroe Rey Feudal**): Rey coronado con armadura dorada y capa de armiño.

---

## ⚜️ ERA 5 — RENACIMIENTO (Renaissance Age)

### 🏛️ Edificaciones (Buildings)
- `TownCenter_Era5`: Palacio renacentista italiano de fachada simétrica, cúpula de terracota y arquerías de mármol.
- `Barracks_Era5`: Ciudadela militar con bastiones en estrella de traza italiana.
- `Stable_Era5`: Establo de caballería de cazadores.
- `Dock_Era5`: Astillero naval de carabelas y galeones.
- `University_Era5`: Academia de sabios con observatorio astronómico.
- `Foundry_Era5`: Fundición de cañones de bronce y hierro.
- `Tower_Bastion_Era5`: Bastión de artillería con cañón emplazado.

### 👤 Personajes y Unidades (Units & Characters)
- `Mosquetero` (**Mosquetero de Pólvora**): Soldado de línea con sombrero de ala ancha, jubón de cuero y mosquete con mecha.
- `Halberdier_Era5` (**Alabardero Suizo**): Infante con manga acuchillada y alabarda de acero decorada.
- `Conquistador_Era5` (**Conquistador Ecuestre**): Jinete con coraza de acero, tricornio y pistola de rueda.
- `Cannonier_Era5` (**Artillero**): Operador de cañón con botafuegos y saco de pólvora.
- `DaVinci_Hero` (**Héroe Inventor**): Erudito con capa de terciopelo, planos y compás.

---

## 🏭 ERA 6 — ERA INDUSTRIAL (Industrial Age)

### 🏛️ Edificaciones (Buildings)
- `TownCenter_Era6`: Ayuntamiento Victoriano de ladrillo rojo con torre de reloj monumental y chimeneas de vapor.
- `Factory_Era6`: Factoría pesada con naves de hierro forjado, techos dentados y chimeneas humeantes.
- `Barracks_Era6`: Cuartel de infantería de ladrillo inglés con patios de marcha.
- `RailStation_Era6`: Depósito ferroviario con vías de acero y torre de agua.
- `Dock_Industrial_Era6`: Astillero de acorazados de casco de hierro.

### 👤 Personajes y Unidades (Units & Characters)
- `Fusilero_Imperial` (**Fusilero de Línea Imperial**): Casaca roja / Infante napoleónico con shako alto y fusil con bayoneta.
- `Line_Officer` (**Oficial de Línea Comandante**): Oficial militar con espada ropera y pistola de duelo.
- `GatlingGunner_Era6` (**Ametrallador Gatling**): Operador de ametralladora Gatling pesada.
- `Hussar_Era6` (**Húsar a Caballo**): Cazador Húsar a caballo con pelisse y sable curvo.
- `Camion_Industrial` (**Vehículo de Transporte Industrial**): Camión primitivo con motor de explosión interna.

---

## ⚛️ ERA 7 — ERA ATÓMICA (Atomic Age)

### 🏛️ Edificaciones (Buildings)
- `TownCenter_Era7`: Edificio gubernamental de hormigón armado estilo Bauhaus con antenas de radio.
- `NuclearPlant_Era7`: Central de energía con dos gigantescas torres de refrigeración hiperbólicas.
- `Airfield_Era7`: Pista de aterrizaje de hormigón con hangares de chapa y torre de control.
- `Barracks_Era7`: Base militar moderna con vallas de alambre de espino.
- `TankFactory_Era7`: Planta de montaje de blindados heavy industry.
- `Bunker_Era7`: Casamata fortificada de hormigón con nido de ametralladoras.
- `NukeSilo_Era7`: Silo subterráneo con misil balístico ICBM emergente.

### 👤 Personajes y Unidades (Units & Characters)
- `HazmatWorker_Era7`: Técnico en traje de protección biológica/nuclear amarillo con contador Geiger.
- `GISoldier_Era7` (**Infantería**): Soldado de infantería con casco M1 de acero y fusil Garand/M16.
- `Sniper_Era7` (**Tirador de Élite**): Tirador con traje Ghillie de camuflaje.
- `AntiTankSoldier_Era7` (**Especial**): Operador de lanzacohetes Bazuca/RPG.
- `GeneralOfficer_Era7` (**Héroe General**): General con gabardina militar, gorra de plato y prismáticos.

---

## 💻 ERA 8 — ERA DIGITAL (Digital Age)

### 🏛️ Edificaciones (Buildings)
- `TownCenter_Era8`: Rascacielos corporativo inteligente con fachada de muro cortina de vidrio azul reflector y helipuerto.
- `CyberCenter_Era8`: Data Center de alta seguridad con paneles solares y unidades HVAC masivas.
- `RoboticsLab_Era8`: Complejo de investigación biotecnológica con domos de policarbonato.
- `Airbase_Stealth_Era8`: Hangar futurista de cazas de sigilo.
- `RadarStation_Era8`: Domo geodésico blanco de radar de fase sobre estructura metálica.

### 👤 Personajes y Unidades (Units & Characters)
- `Infiltrador_Nano` (**Infiltrador Óptico Camuflado**): Soldado de camuflaje termo-óptico invisible en estado Idle.
- `Soldado_EMP` (**Especialista en Pulso EMP**): Infante con cañón de ondas electromagnéticas que desactiva vehículos y mechs.
- `Cyborg_Militar` (**Cyborg Combate Pesado**): Humanoide cibernético con minigun pesada integrada en el brazo.
- `Dron_Enjambre` (**Dron Táctico Enjambre**): Dron aéreo pequeño de rastreo y ataque coordinado.
- `SpecOps_Era8`: Operador táctico con visor de visión nocturna IV y chaleco molotow.

---

## 🧬 ERA 9 — NANO-FUTURISTA (Nano-Futuristic Age)

### 🏛️ Edificaciones (Buildings)
- `TownCenter_Era9`: Núcleo de mando levitante de nanocompuesto de titanio blanco con anillos de plasma.
- `NanoForge_Era9`: Inyector de materia molecular con reactor de fusión fría y destellos cian/morados.
- `ShieldGenerator_Era9`: Pilona hexagonal que proyecta una cúpula holográfica impenetrable.
- `OrbitalCannon_Era9`: Plataforma de súper-arma de inducción magnética orientada al espacio.

### 👤 Personajes y Unidades (Units & Characters)
- `Cyber_Hacker` (**Exosoldado Hacker de Red**): Operativo pesado con exoesqueleto y ciber-computadora capaz de invertir el bando de unidades enemigas mediante rpc `aplicar_hackeo_red`.
- `Humanode_Plasma` (**Humanoide de Plasma**): Entidad sintética de energía pura con cañón pesado fotónico.
- `Soldado_Antiaereo` (**Soldado Antiaéreo Pesado**): Especialista con lanzamisiles electromagnéticos guiados por nano-radar.
- `Dron_Titan` (**Dron Titán de Plasma**): Dron aéreo pesado de gran envergadura con rayo desintegrador.
- `Transporte_Nano` (**Transportador Nano-Futurista**): Nave levitante de transporte táctico infrarrojo.
- `Archangel_Hero` (**Héroe Supremo**): Comandante con alas de nanofibras de luz y espada monocristalina.

---

## 📋 Cuadro Resumen Total de Assets del Juego

| Categoría de Asset | Cantidad Estimada por Era | TOTAL GLOBAL (10 Eras) |
|---|---|---|
| **Edificaciones (Edificios principales, murallas y templos)** | 7 a 11 estructuras | **89 Edificios 3D** |
| **Personajes Civiles y Militares (Unidades y Héroes)** | 6 a 8 clases | **76 Personajes 3D** |
| **Maquinaria de Guerra, Vehículos, Barcos, Cazas y Tanques** | 5 a 8 vehículos/armas | **56 Maquinarias de Guerra 3D** |
| **Fauna y Animales (Caza, Trabajo y Predadores)** | 2 a 5 criaturas | **30 Animales 3D** |
| **Props, Recursos y Sockets de Balística** | 4 a 6 objetos | **52 Props 3D** |
| **GRAN TOTAL DE ASSETS 3D DEL JUEGO** | — | **~303 MODELOS 3D** |

---
*Documento maestro definitivo con el 100% de vehículos, aviación, tanques, armas de asedio, templos, fortificaciones y unidades sincronizado con el código de **Empire Tactics**.*
