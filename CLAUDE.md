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
- [ ] Paso 4+ — tema/colores (`AppTheme.json`), fuentes (`FontManager.brs`), imágenes de marca definitivas, reescritura de `ContentAPI.brs`/`BaseRequests.brs`, resto de la migración.
