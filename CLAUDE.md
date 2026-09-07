# CLAUDE.md — reglas de trabajo en este proyecto

## Qué es esto

Canal Roku (BrightScript/SceneGraph) para el cliente **13go** (Canal 13, Chile), construido como copia y aprendizaje a partir de [`../roku-chv`](../roku-chv) (cliente MiCHV). El dueño del proyecto está aprendiendo Roku/BrightScript desde cero mientras lo construye.

## Cómo trabajar en este proyecto (importante, no lo ignores)

- **Modo profesor, no modo autopiloto.** Para cada paso: explica el concepto (qué archivo, por qué existe, cómo encaja en la arquitectura SceneGraph/BrightScript) y **dale el código al usuario para que él lo transcriba y aplique**. No edites archivos de código (BrightScript, XML, JSON de configuración) por tu cuenta.
- Excepción: si el usuario dice explícitamente "hazlo tú" / "dale" / equivalente para un paso puntual, aplícalo tú — pero esto no se extiende a los pasos siguientes, vuelve a preguntar o a dar el código para transcribir.
- Tareas puramente mecánicas que el usuario pida directamente (copiar carpetas, `git init`, mover archivos) sí se pueden ejecutar directamente, no tienen valor de aprendizaje.
- Ve paso a paso. No te adelantes a fases futuras del plan sin que el usuario lo pida — aunque tengas contexto para hacerlo, la idea es que él controle el ritmo.
- Actualiza la sección "Estado actual" de este archivo a medida que se completen pasos, para que cualquier sesión futura (tuya o de otra persona) sepa exactamente dónde retomar sin releer todo el historial.

## Contexto del backend de 13go (clave — no asumir que es igual a MiCHV)

- MiCHV (`roku-chv`) usa REST directo en `consumers.rudo.video/{recurso}` con `client=chv` para catálogo, perfiles y auth.
- **13go usa un patrón distinto:**
  - Catálogo (programas/categorías/videos): feed tipo WordPress en `www.13.cl/13go-premium/feed/...`.
  - Perfiles: proxy a Firebase en `https://rudo.video/gateway/13go/` — POST con `FormData` y campos `action=firebase`, `path=...`, `token=...`.
  - Referencia real de estos endpoints: proyecto React `c13_reloaded` en `C:\Users\Joaquin\Documents\projects\c13_reloaded` (ver `src/config-global.ts` y `src/services/*.ts`).
- Streaming/EPG/playlists sí comparten el CDN de rudo.video, pero bajo el slug de tenant `canal-13` (no `13go`) — ej. `cdn.rudo.video/assets/canal-13/playlists/...`.
- **Decisión tomada (2026-09-03):** replicar exactamente el comportamiento de `c13_reloaded`, no reutilizar el patrón REST de MiCHV. Esto implica reescribir `source/apis/ContentAPI.brs` y `source/apis/BaseRequests.brs` más adelante, no solo cambiar `AppConfig.json`.

## Proyecto de referencia: `c13_reloaded`

`c13_reloaded` es la app web (React + Vite + TS) de 13go **ya funcional en producción** — es la fuente de verdad de negocio/backend/marca para este puerto a Roku. Ruta completa:

```
C:\Users\Joaquin\Documents\projects\c13_reloaded
```

No hay que "buscarlo" cada vez — este es el mapa de las rutas que ya importan dentro de ese proyecto:

```
c13_reloaded/
├── config.json                        # secciones/orden de la home (tipo "destacados", "categoria_carrusel", etc.)
├── src/
│   ├── config-global.ts               # ⭐ TODAS las URLs base (feed 13.cl, rudo CDN, gateway Firebase, access token)
│   ├── App.tsx / main.tsx             # bootstrap de la app (equivalente conceptual a Main() + MainScene)
│   ├── router/
│   │   ├── index.tsx                  # definición de rutas = equivalente a las "páginas" del ViewStackManager
│   │   └── config.tsx
│   ├── layout/
│   │   ├── MainLayout.tsx             # shell con sidebar = equivalente a MainScene + TopMenu
│   │   ├── AuthGuard.tsx              # lógica de "¿está logueado?" = equivalente a isUserLoggedIn en MainScene
│   │   └── components/Sidebar.tsx     # menú lateral = equivalente a TopMenu
│   ├── pages/                         # ⭐ una carpeta por pantalla — mapea 1:1 a components/pages/* en el Roku
│   │   ├── Splash/SplashView.tsx      # → OnboardingPage
│   │   ├── WhosThere/                 # → EditorProfilesPage (selección de perfil)
│   │   ├── Auth/
│   │   │   ├── ConnectView.tsx        # → DeviceLinkPage (vincular TV / QR)
│   │   │   ├── LoginView.tsx          # → LoginPage
│   │   │   ├── RegisterView.tsx       # → SignUpPage
│   │   │   └── SuscribeView.tsx
│   │   ├── Home/HomeView.tsx          # → HomePage
│   │   ├── Live/LiveView.tsx          # → LivePage
│   │   ├── Radio/RadioView.tsx        # (no existe en MiCHV — feature nueva a evaluar)
│   │   ├── Search/SearchView.tsx      # → SearchPage
│   │   ├── VOD/
│   │   │   ├── VODView.tsx            # → CategoryDetailPage / ProgramsPage
│   │   │   ├── Program/               # → DetailPage
│   │   │   └── Player/                # → VideoPlayer
│   │   └── Account/
│   │       ├── AccountView.tsx        # → AccountPage
│   │       └── EditProfileView.tsx    # → EditorProfilesPage (edición)
│   ├── services/                      # ⭐⭐ LA REFERENCIA para reescribir ContentAPI.brs/BaseRequests.brs
│   │   ├── rudo.ts                    # cliente base hacia rudo.video (streaming/EPG)
│   │   ├── canal13GoService.ts        # catálogo VOD: programas, categorías, capítulos (feed 13.cl)
│   │   ├── homeSectionsService.ts     # arma las filas de la home según config.json
│   │   ├── searchService.ts           # búsqueda
│   │   ├── favoriteService.ts         # favoritos / "mi lista"
│   │   ├── profileService.ts          # perfiles vía gateway Firebase (action=firebase)
│   │   ├── hlsSessionService.ts       # sesión de reproducción HLS
│   │   ├── deviceAdService.ts         # anuncios (VAST/VMAP) — cruza con roku_ads_lib/googleima3 del manifest
│   │   ├── ga4Service.ts / trackingService.ts  # analítica (evaluar si aplica igual en TV)
│   │   └── globlalService.ts          # (sic, typo en el nombre real del archivo) config global / bootstrap
│   ├── features/auth/                 # lógica de autenticación (context, hooks, services, types.ts)
│   ├── hooks/                         # use-home-data.ts, use-vod-data.ts, use-program-data.ts, etc. — piensa
│   │                                   # estos como "la versión React" de lo que en Roku son las funciones
│   │                                   # `On...APIResponse` en cada página (mismo rol: pedir datos y mapearlos a UI)
│   ├── interfaces/                    # tipos TS de las respuestas de API — úsalos como referencia de la forma
│   │                                   # real del JSON al escribir los parsers .brs (ej. HomePageParser.brs)
│   └── assets/
│       ├── fonts/                     # DMSans-*.ttf (usar estos en el Roku), CircularXX-*.woff2 (solo web)
│       └── images/
│           ├── logos/                 # 13-go-logo.png ⭐ logo oficial
│           ├── qr/                    # qr-13-go-tv-rounded.png, qr-13go-tv.png, etc.
│           ├── backgrounds/           # bg-start.png, bg-linear-gradient-main.png
│           └── buttons/ , iconos/     # iconografía de referencia (formato SVG/PNG, hay que exportar a Roku)
└── apps/tizen, apps/webos             # builds empaquetados para otras TVs — no relevantes para el puerto Roku
```

**Regla práctica:** cuando lleguemos a reescribir una función de `ContentAPI.brs`, el primer lugar donde buscar el endpoint/forma de los datos es el archivo de `src/services/*.ts` equivalente, no adivinar.

## Assets de marca reales (extraídos de `c13_reloaded/src/assets`)

- Logo: `images/logos/13-go-logo.png`.
- Color primario: `#FA6428` (naranjo). Fondos oscuros: `#08090C` / `#060608` / `#1C1D28`. Acento: amarillo `#ffcf04`.
- Tipografía: **DMSans** (ttf, varios pesos) en `assets/fonts/`.
- Íconos/splash con tamaño exacto que exige Roku: **pendientes**. No asumas medidas de memoria — verifica contra la documentación oficial de Roku antes de exportar los finales.

## Comandos

No hay `package.json` ni build system: este es un canal Roku puro (BrightScript + SceneGraph XML), sin transpilación ni bundler.

- **Formato de código:** [bsfmt.json](bsfmt.json) define el estilo (4 espacios, `LF`, `AND`/`OR` en mayúsculas, resto de keywords en su casing original) para el formateador `bsfmt` (paquete `brighterscript-formatter`) — si el usuario lo tiene instalado, se corre como `bsfmt --config bsfmt.json` sobre los `.brs` modificados. No hay linter (`bslint`/`.bsconfig`) configurado en el repo.
- **Empaquetar y probar en un Roku real:** no hay script propio en el repo; es el flujo estándar de sideload de Roku — comprimir el proyecto (manifest + carpetas en la raíz) en un zip y subirlo vía `http://<ip-del-roku>/plugin_install` (form `mysubmit=Install`, modo desarrollador activo en el dispositivo). El log en vivo se ve por telnet al puerto 8085 del Roku.
- **Pruebas automatizadas:** no existen (no hay carpeta `tests/`). Las carpetas [rasp/](rasp/) contienen scripts RASP (Roku Automated Screenshot Program) para certificación/QA manual guiada, no tests unitarios — y aún referencian el canal `MiCHV` (pendiente de actualizar a 13go cuando se llegue a esa fase).
- **Probar sin un Roku físico:** `brs-node` (motor de simulación BrightScript de la comunidad, [lvcabral/brs-engine](https://github.com/lvcabral/brs-engine)) corre el canal empaquetado en un `.zip` desde la terminal, con `print`/logs reales y sin las limitaciones de CORS del navegador (las llamadas de red sí funcionan, corren desde Node). Uso: `npm install brs-node` en un proyecto scratch, después `npx brs-cli --log-level debug ruta/al/canal.zip`. **Ojo al empaquetar el zip en Windows:** `Compress-Archive` de PowerShell guarda las rutas internas con `\` en vez de `/`, lo cual rompe la resolución de `pkg:/...` — hay que armar el zip con una herramienta que use `/` (ej. `adm-zip` de Node, o `zip` de Git Bash/WSL si está disponible).

## Arquitectura de alto nivel

- **Arranque:** [source/main.brs](source/main.brs) es el entry point BrightScript puro: crea el `roSGScreen`, instancia la escena `MainScene`, resuelve deep linking desde `args` o `roInputEvent`, y bombea el loop de mensajes (`wait(0, port)`). Todo lo demás vive dentro de la escena SceneGraph.
- **Nodo global (`m.global`):** [source/helpers/Global.brs](source/helpers/Global.brs) → `SetGlobalNode()` (llamado una sola vez desde `MainScene.Init()`) carga `AppConfig.json` y `AppTheme.json` del paquete, arma `apiEndPoints`, crea el `FontManager`, y guarda todo en `m.global`. Cualquier componente accede a esto vía `m.global.appConfig` / `m.global.appTheme` / `m.global.Fonts`, sin pasar props manualmente.
- **`MainScene` como router manual:** [components/scene/MainScene.brs](components/scene/MainScene.brs) es el controlador central — no hay un sistema de rutas declarativo. Por cada página existe un par `ShowXPage()` / `GetXPageObject()`: el segundo crea (o reutiliza) el nodo SceneGraph de esa página como hijo de `gPageContainer`, y el primero lo empuja al stack de navegación. Sigue este patrón al agregar una página nueva.
- **`ViewStackManager`:** [source/managers/ViewStackManager.brs](source/managers/ViewStackManager.brs) es una pila simple de nodos (`ShowScreen`/`HideTop`/`ReplaceScreen`/`FocusTop`) que `MainScene` usa para mostrar/ocultar páginas y devolver el foco. El botón `back` se maneja centralizado en `MainScene.HandleBackKey()` (dentro de `OnkeyEvent`), no en cada página.
- **Llamadas a red vía Task nodes (patrón async):** las páginas nunca golpean la red directo. Crean un nodo `roSGNode` de tipo Task (`components/tasks/ContentAPIAction`, `AuthAPIAction`, `DAIPlayerTask`), setean `functionName` + `params`, observan el campo `result`, y disparan con `control = "RUN"`. El `.brs` del Task (ej. [components/tasks/ContentAPIAction/ContentAPIAction.brs](components/tasks/ContentAPIAction/ContentAPIAction.brs)) despacha por nombre de función hacia la capa de API y escribe la respuesta en `m.top.result` — corre en su propio hilo, evitando bloquear la UI. Ver `MainScene.GetConfig()` / `OnGetConfigAPIResponse` como ejemplo completo del ciclo.
- **Capa de API en dos niveles:**
  - [source/apis/BaseRequests.brs](source/apis/BaseRequests.brs): HTTP crudo sobre `roUrlTransfer` (`getRequest`/`postRequest`/`deleteRequest`), siempre retorna `{isSuccess, response}` o `{isSuccess:false, code, reason}` vía los helpers `success()`/`fail()`.
  - [source/apis/ContentAPI.brs](source/apis/ContentAPI.brs): compone esas llamadas en endpoints concretos del backend. **Hoy todavía habla el patrón MiCHV/rudo.video** — es el archivo que hay que reescribir cuando se aborde el Paso 3+ (ver "Contexto del backend de 13go" arriba).
- **Persistencia local:** [source/managers/RegistryManager.brs](source/managers/RegistryManager.brs) envuelve `roRegistrySection` para guardar/leer token de sesión y datos de usuario entre lanzamientos del canal.
- **Deep linking:** el formato de `contentId` es `clave=valor` separado por `|` (ej. `programId=X|segmentId=Y|seasonId=Z|episodeId=W`), parseado en `MainScene.splitDeeplinkingData()`. `mediaType` soportados: `movie`, `season`, `episode`, `series`, `live` (`IsSupportedDeepLinkMediaType`). Los VOD/movie deeplinks resuelven vía `programs/get` y la app abre el primer episodio reproducible.

## Estado actual (ir marcando)

- [x] Paso 1 — Copia de `roku-chv` a `roku_13go`, `.git` reiniciado.
- [x] Paso 2 — `manifest`: `title=13GO`, `build_version=090320260`.
- [x] Paso 3 — `AppConfig.json` (feed 13.cl + gateway Firebase + CDN `canal-13`) y `Global.brs::GetApiEndPoints()` reescritos. Nota clave descubierta: auth y perfiles en 13go NO son endpoints REST por acción — es un único `gatewayUrl` (`https://rudo.video/gateway/13go/`) diferenciado por el campo `action`/`path` del POST (ver `c13_reloaded/src/features/auth/services/authentication.ts` y `src/services/profileService.ts`). Eso se resuelve recién en el Paso 4, al reescribir `ContentAPI.brs`/`BaseRequests.brs`.
- [x] Paso 4a — tema/colores: `AppTheme.json` con paleta real de 13go (`#FA6428` naranjo, fondos `#08090C`/`#1C1D28`, acento `#ffcf04`), mapeada revisando el uso real de cada clave en `components/`.
- [x] Paso 4b — fuentes: `FontManager.brs` y las ~35 páginas/controles que lo consumían migrados de Poppins a DMSans (`fonts/DMSans-*.ttf`), incluyendo renombrar `poppins*` → `dmSans*` en todo el código y corregir 3 rutas de fuente hardcodeadas fuera de `FontManager.brs` (`LoginPage.brs`, `SignUpPage.brs`, `OnboardingPage.brs`).
- [x] Paso 4c — íconos/splash/logo placeholder con marca 13go real (logo `c13_reloaded/src/assets/images/logos/13-go-logo.png` compuesto sobre fondo `#08090C`, tamaños verificados contra la documentación oficial de Roku: íconos 540×405/290×218/246×140, splash 1920×1080/1280×720/720×480). Es un placeholder centrado, no un diseño "a sangre" — pendiente de refinar cuando haya assets de diseño definitivos.
- [ ] Paso 4d — reescritura de `ContentAPI.brs`/`BaseRequests.brs`: auth y perfiles van por el gateway único (`action`/`path`, ver Paso 3), catálogo por el feed de 13.cl. `BaseRequests.brs` hoy no soporta ese patrón, hay que revisarlo función por función contra `c13_reloaded/src/services/*.ts` y `src/features/auth/services/*.ts`. Hallazgo clave: el Home de 13go es **config-driven** (`configuracion-portada` trae una lista de secciones con distinto `despliegue`, varias apuntan a URLs que vienen dentro de la propia respuesta de `configuracion`), no una lista fija de categorías como MiCHV — esto también va a tocar `MainScene.brs`/`HomePage.brs`, no solo la capa de API. Mini-roadmap acordado:
  - [x] 4d.1 — `GetConfig` end-to-end: `ContentAPI.brs::ContentAPI__GetConfig()` (GET público al feed, sin `client`) + `MainScene.OnGetConfigAPIResponse()` con campos reales (`logo_blanco`, `fondo_bienvenida`; `vastURL`/`urlTVVincular` no existen en este config, quedan en `""` hasta los sub-pasos de ads/device-link). De paso, renombradas las ~30 funciones internas de `ContentAPI.brs` de `TVCHVContentAPI__*` a `ContentAPI__*` (prefijo genérico, sin nombre de cliente).
  - [x] 4d.2 — Catálogo VOD completo (`ContentAPI__GetPrograms` → `feed/programas`, agrupado por categoría, sin paginar) conectado a `ProgramsPage.brs`. Aclarado con el propio `c13_reloaded` (`hooks/use-vod-data.ts`) que este feed alimenta la pantalla VOD/catálogo, no el Home — `HomePage.brs::GetAllCategories` sigue roto/MiCHV hasta el sub-paso 4d.3. Nota de datos: en cada item del feed, `key` es el id de la **categoría** (no del programa) — se usa `id` como key real del programa. Queda pendiente `GetProgramDetails`/`DetailPage.brs` (detalle de programa, otro sub-paso).
  - [x] 4d.3 — Home config-driven (armado de filas según `configuracion-portada`). Sub-dividido:
    - [x] 4d.3-A — esqueleto de orquestación (`ContentAPI__GetHomeConfig` trae `configuracion-portada`, `MainScene` guarda el config completo en `m.global.homeConfig` porque varias URLs de sección son dinámicas) + sección `destacados` completa end-to-end (hero + fila), verificado en vivo contra el feed real (shape de episodio: `title`/`image`/`bajada`/`nid`, no el shape de programa del catálogo).
    - [x] 4d.3-B — resto de tipos de sección conectados, todos verificados en vivo: `categoria_carrusel`/`categoria_destacada` (`feed/categorias/{id}` → `{programs:[...]}`), `top10` (`masvistos` → `{data:[...]}`), `senales` (`senales` → array de canales en vivo), `radios` (`radios` → array). Cambio de arquitectura: `ProcessNextHomeSection()` recorre las secciones de a una en secuencia (no en paralelo) para respetar el orden del CMS. Se recicló el endpoint/función muerta `GetAllCategories` como `GetCategoryPrograms`, y se renombró `ContentAPI__GetFeaturedSliderPrograms` → `ContentAPI__GetJsonByUrl` (genérico, ahora se reutiliza para destacados/top10/señales/radios). Nota: señales y radios se ven en el Home pero todavía no reproducen nada — eso requiere reproductor de audio/canal en vivo, pendiente.
    - **Verificado end-to-end con `brs-node` (ver "Comandos"):** el canal corre de punta a punta contra los feeds reales de 13go sin crashear, procesando las 8 secciones activas en el orden correcto. Esa prueba encontró un bug real (no solo de transcripción): `destacados_principales` y `masvistos` vienen envueltos como `{"data": [...]}` en el JSON crudo, que sumado al wrapper propio de `handleApiResponse()` da dos niveles (`apiResponse.data.data`, no `apiResponse.data`) — `OnGetFeaturedSliderProgramsAPIResponse` y `OnGetHomeTop10APIResponse` en `HomePage.brs` usaban solo un nivel. `senales`/`radios` sí son arrays planos (un solo nivel está bien ahí).
  - [ ] 4d.4 — Auth + perfiles vía gateway (`action`/`path`) — device linking, login, perfiles.
  - [ ] 4d.5 — Favoritos / historial / EPG.
- [ ] Paso 5 — Paridad visual con `c13_reloaded` (sidebar + Home). Decisión (2026-09-07): calcar lo más posible el diseño real de la web, verificado en vivo (login real, `npm run dev` de `c13_reloaded` en `localhost:3000`) — no solo el código. Techo realista: SceneGraph no tiene CSS ni las animaciones de un navegador, se apunta a "lo más parecido posible" (colores/proporciones/iconografía), no pixel-perfect. Hallazgo clave: cada tipo de sección del Home tiene un estilo visual propio y distinto en la web (`categoria_carrusel` = tarjetas con badge "Premium", `categoria_destacada` = carrusel "monumental" tipo banner, `top10` = tarjetas con número de ranking gigante, `senales`/`radios` = círculos con logo) — hoy en Roku todas se ven igual (fila genérica `SliderView`+`ProgramItemNode`). Mini-roadmap:
  - [x] Sidebar 1/3 — riel vertical de íconos (sin expandir/colapsar todavía). `TopMenu`/`MenuContentItem` pasaron de grilla horizontal de texto (7 cols x 1 fila) a vertical de íconos (1 col x 5 filas), con los 5 ítems calcados de `c13_reloaded` (Portada/Programas/En vivo/Radios/Búsqueda — se sacó "Mi Lista" del menú principal, decisión explícita del usuario). Íconos reales exportados de `c13_reloaded/src/assets/images/iconos/*.svg` (SVG, Roku no los renderiza) a PNG transparente vía `sharp` en `images/icons/sidebar/`. Color del ícono por estado (blanco foco / naranjo activo / gris inactivo) vía `blendColor`, igual que el texto lo hacía en la versión vieja. Logo y avatar/login quedan sin reubicar (es la parte 3/3) — layout transitorio esperado.
  - [x] Sidebar 2/3 — expandir/colapsar con foco: `MenuContent` ganó el campo `isExpanded` (mismo patrón que `isSelected`), `TopMenu.OnFocusChild()` lo propaga a todos los items cuando `topMenuGrid` tiene foco (`SetMenuExpanded()`), y cada `MenuContentItem` muestra/oculta su `Label` de título con el mismo color que el ícono (blanco foco / naranjo activo / gris inactivo). Hubo que agrandar `itemSize` del grid (90→260 de ancho) porque `MarkupGrid` recorta cada item a su tamaño declarado.
  - [ ] Sidebar 3/3 (avatar/login) y Paso 4d.4/4d.5 (auth, perfiles, favoritos) — **en standby a propósito** (decisión del usuario, 2026-09-07): requieren estar logueado, y el usuario prefiere dejarlo para el final para no tener que iniciar sesión en cada prueba mientras se hace el resto del trabajo visual. Sidebar 3/3 además tiene pendiente definir si se integra como primer ítem de la grilla (navegación arriba/abajo, más fiel a `c13_reloaded` pero más riesgo) o solo se reposiciona el `Group` actual (más simple).
  - [x] Home — títulos de fila con tipografía de marca: `RowList` nativo de Roku no tenía `rowLabelFont`/`rowLabelColor` seteados en `SliderView.brs` (sí lo tenía `ProgramsPage.brs`, ahí se encontró la referencia) — salían con la fuente default del sistema. Se agregó `m.rowList.rowLabelFont = m.fonts.dmSansBold32` / `rowLabelColor = m.theme.white`, acercándose al `titulo-2` de `c13_reloaded` (bold, grande) con el peso más pesado de DMSans que tenemos importado (Bold).
  - [x] Home — fondo: `MainScene.brs` seteaba `backgroundURI = "pkg:/images/other/bg_home.png"` (textura vieja de MiCHV) — se cambió a `backgroundColor = m.theme.clrPrimary` (`#08090C` sólido), que es lo que usa `c13_reloaded`.
  - [x] Bug real encontrado probando en un Roku físico (primera vez que se prueba fuera de `brs-node`, vía telnet puerto 8085): al pasar el sidebar de horizontal a vertical, nadie había actualizado la navegación de foco. `MainScene.brs::OnkeyEvent()` seguía usando arriba/abajo para entrar/salir del menú (correcto para el diseño horizontal viejo, no para un riel vertical a la izquierda) — se cambió a izquierda/derecha. Además `TopMenu.brs::onKeyEvent()` interceptaba "derecha" incondicionalmente para saltar al avatar/login (lógica del diseño horizontal, donde el perfil estaba a la derecha del menú) — eso bloqueaba que "derecha" volviera al contenido de la página. Se desactivó ese salto automático (queda pendiente de rediseñar junto con Sidebar 3/3).
  - [x] Bug real #2, mismo dispositivo: el foco ya llegaba al riel pero no expandía (no se veía el texto). `TopMenu.brs::OnFocusChild()` inferír "¿la grilla tiene foco?" leyendo `m.top.focusedChild.id`, un campo con timing indirecto que interactúa mal con la redirección de foco de `RestoreFocus()`/el salto al perfil. Se cambió a preguntarle directo a la grilla (`m.topMenuGrid.hasFocus() OR m.topMenuGrid.isInFocusChain()`), más confiable.
  - [x] Bug real #3 (crash), encontrado con el debugger BrightScript real (telnet): `HomePage.brs::OnGetFeaturedSliderProgramsAPIResponse` — `m.heroSlider.componentHeight = 583` tiraba "Invalid value for left-side of expression" **a pesar de** estar adentro de un `if isValid(m.heroSlider)`. Causa: asignar `m.heroSlider.items = [...]` dispara sincrónicamente `HeroSlider::onItemsSet()`, que mueve el foco al botón "Ver ahora" — eso puede encadenar hasta `initVar()` (que pone `m.heroSlider = invalid`) si hay una navegación fuera del Home ocurriendo casi en simultáneo (condición de carrera). Fix: guardar `m.heroSlider` en una variable local antes de usarlo repetidas veces en el mismo bloque, para no depender de que el campo `m` siga apuntando a lo mismo a mitad de camino.
  - [x] Bug real #4, mismo dispositivo: seleccionar cualquier ítem del sidebar (incluso "Portada" estando ya en el Home) recargaba el Home entero desde cero. Causa real, confirmada con un `print` de diagnóstico: la grilla vertical dispara `itemSelected`/`selectedItem` con el ítem "Portada" apenas el foco entra al riel — sin que el usuario apriete OK — y `MainScene.brs::onTopMenuItemSelected()` no chequeaba si esa página ya era la actual antes de destruir y reconstruir todo (`ShowHomePage(true)` siempre fuerza replace). Fix: comparar contra `m.ViewStackManager.GetTop().id` antes de navegar, y no hacer nada si ya se está en esa página.
  - [x] Hero simple ("destacados") vs. carrusel monumental ("categoria_destacada") en realidad son **dos layouts distintos** en `c13_reloaded`, no el mismo con distinto contenido — se descubrió leyendo `panels_new.css`/`DynamicBanner.tsx` reales (no había forma de verlo bien sin loguearse, así que se instaló Claude in Chrome para poder inspeccionar la web real cuando haga falta). El hero simple (`.destacados-1`) tiene la imagen **chica** (72vw × 41vw) arriba a la derecha, sin degradado, con el texto en una columna aparte a la izquierda (32vw) — nuestro `HeroSlider` hacía lo del carrusel monumental (imagen de fondo completa + degradado + texto encima) para los dos casos. Se le agregó un campo `variant` (`"full"` default = comportamiento monumental sin cambios, `"compact"` = imagen chica arriba a la derecha, con dos degradados hacia `#08090C` — abajo y a la izquierda, generados como PNG con `sharp` ya que Roku no tiene gradientes CSS — y texto a la izquierda con su propio ancho). `HomePage.brs` solo setea `variant="compact"` en el hero de arriba. Pendiente de ajuste fino de medidas una vez visto en pantalla real (`brs-node` no renderiza píxeles).
  - [x] Home — badge "Premium" en tarjetas de `categoria_carrusel`: **no había nada que construir**. Confirmado bajando la imagen real (`raw.image` de `feed/categorias/{id}`) que el badge está grabado en los píxeles del JPG por el CMS (la URL usa el "image style" de Drupal `13go_vertical_premium`) — no es un overlay de la UI. `OnGetHomeCategoryProgramsAPIResponse` ya usa ese campo `image`, así que el badge aparece solo. El único "Premium" real en el código de `c13_reloaded` (`.menu .avatar .premium`) es el anillo de la cuenta premium en el sidebar, sin relación con esto — es parte del Sidebar 3/3, pospuesto.
  - [x] Home — círculos de logo para `senales`/`radios`: nuevo branch `format="circle"` en `CommonItemComponent`, reusando el patrón de `AvatarListItem` (un `MaskGroup` con `profile_mask.png` como máscara circular). Anillo de color (`images/masks/circle_ring.png`, generado con `sharp` a partir de un SVG) teñido vía `blendColor` con el color real de cada canal/radio (`color_principal`/`color` del feed). `PushHomeRow` ganó un parámetro `componentHeight` para que estas filas no usen la altura de tarjeta vertical (576px) sino una más chica (220px). Se agregaron los campos `image`/`ringColor` a `ProgramItemNode.xml` (si no, `setFields()` los descarta en silencio por no estar declarados — mismo tipo de bug que ya nos había pasado antes).
  - [x] Home — número de ranking en `top10`: resultó que ya estaba prácticamente construido y sin usar, heredado de MiCHV — `CommonItemComponent.brs` ya sabía dibujar el número (`number_back.png` + `lNumberRightTop`) cuando `image_orientation="portrait"` y `format="ranking"`, y `HomePageParser.brs::createChildNode()` ya le agregaba el campo `number` (1,2,3...) a cada item cuando la fila tenía ese `format`. Solo hizo falta parametrizar `PushHomeRow(title, items, format = "default")` (antes tenía `"default"` fijo) y pasarle `"ranking"` desde `OnGetHomeTop10APIResponse`.
  - [x] Home — carrusel "monumental" para `categoria_destacada`: se reutilizó `HeroSlider` (el mismo componente del hero de "destacados") en vez de crear uno nuevo, agregándole navegación real entre items (`m.activeIndex` + izquierda/derecha, antes esas teclas no hacían nada) — con 1 solo item el ciclo es un no-op, así que no afecta el uso existente del hero. `HomePage.brs` ahora separa `categoria_carrusel` (tarjetas chicas, sin cambios) de `categoria_destacada` (arma un `HeroSlider` con `imagen_fondo` del feed vía `PushMonumentalRow`). Hubo que corregir la condición de visibilidad en `createDynamicRowList()`/`checkRefreshNodes()` (dos lugares) de `node.id = "heroSlider"` (string fijo, solo matcheaba el hero original) a `node.subtype() = "HeroSlider"` (por tipo de nodo), si no las filas monumentales quedaban armadas pero invisibles. Texto del botón corregido de "Play" a "Ver ahora" (aplica también al hero de destacados).
