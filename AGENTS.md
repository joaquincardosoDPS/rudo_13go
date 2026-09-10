# AGENTS.md — roku_13go

Canal Roku (BrightScript/SceneGraph) del cliente **13go** (Canal 13, Chile). Es un puerto
de la web React **`c13_reloaded`** (ya en producción), partiendo del código de un canal
anterior (`../roku-chv`, MiCHV). Objetivo: replicar `c13_reloaded` lo más fielmente posible.

`CLAUDE.md` es el log exhaustivo (estado, roadmap, decisiones, historial de bugs). Este
archivo es el resumen de arranque; para detalle o "¿en qué paso vamos?", leer `CLAUDE.md`.

## Modo de trabajo (leer primero — no ignorar)

- **Modo profesor, no autopiloto.** El dueño está aprendiendo Roku/BrightScript. Para cada
  paso: explica el concepto y **entrega el código para que él lo transcriba**. **No edites
  archivos de código** (`.brs`, `.xml`, `.json` de config) por tu cuenta.
- Excepción: solo si dice explícitamente "hazlo tú"/"dale" para un paso puntual. No se
  extiende al paso siguiente.
- Tareas mecánicas que pida directo (copiar/mover carpetas, `git init`) sí se ejecutan.
- Ve paso a paso; no te adelantes a fases futuras aunque tengas contexto.
- Al completar pasos, actualiza "Estado actual" en `CLAUDE.md`.
- Idioma del proyecto y de los commits: **español** (ej. "Corregir…", "Agregar…").

## Fuentes de verdad

- **`c13_reloaded`** (`C:\Users\Joaquin\Documents\projects\c13_reloaded`) — app web real.
  Para backend/negocio/marca: `src/config-global.ts`, `src/services/*.ts`,
  `src/features/auth/services/*.ts`, `src/hooks/*.ts`, `src/interfaces/*`. Sus tipos TS son
  la forma real del JSON al escribir los parsers `.brs`.
- **Web en vivo:** `npm run dev` de `c13_reloaded` corre en `http://localhost:3000` (ya
  suele estar levantado). Es la referencia visual; algunas pantallas requieren login.
- **Assets de marca:** salen de `c13_reloaded/src/assets` (logo, iconos SVG→PNG vía `sharp`,
  fuentes DMSans). Roku no renderiza SVG.
- `README.md` está **obsoleto** (credenciales y ejemplos de deep link de MiCHV), no es doc de 13go.

## Backend 13go (NO es el de MiCHV — no asumir)

- Catálogo (programas/categorías/videos): feed tipo WordPress en
  `https://www.13.cl/13go-premium/feed/...`.
- Auth y perfiles: **un único gateway** `https://rudo.video/gateway/13go/` — POST con
  `FormData` y campos `action`/`path`/`token` (no REST por acción).
- Streaming/EPG/playlists: CDN `cdn.rudo.video` bajo el slug de tenant **`canal-13`**.
- `ContentAPI.brs` ya migrado parcialmente (GetConfig, GetPrograms, secciones del Home);
  **pendiente**: auth/perfiles (4d.4), favoritos/historial/EPG (4d.5).
- El Home es **config-driven**: `configuracion-portada` trae secciones con `despliegue` y
  URLs dinámicas (se guardan en `m.global.homeConfig`); `ProcessNextHomeSection()` las
  procesa **secuencialmente** para respetar el orden del CMS.

## Comandos

- **No hay `package.json` ni build system** — canal Roku puro. No busques `npm test`/lint.
- **Formato:** `bsfmt --config bsfmt.json` (paquete `brighterscript-formatter`) sobre los
  `.brs` modificados. No hay linter ni `.bsconfig`.
- **Roku real:** zip de `manifest` + carpetas de primer nivel, subir a
  `http://<ip-roku>/plugin_install` (`mysubmit=Install`, modo desarrollador activo). Log en
  vivo por telnet al puerto `8085`.
- **Empaquetado (hacerlo tras cada cambio de código):** generar `canal13go.zip` en la raíz
  con `manifest` + `components/`, `source/`, `images/`, `fonts/` (NO incluir `rasp/`, docs,
  `.claude/`). Las rutas internas deben usar `/`. `Compress-Archive` de PowerShell las rompe;
  usar `[System.IO.Compression.ZipFile]` con nombre de entrada explícito (cargar ANTES
  `Add-Type -AssemblyName System.IO.Compression` y `...Compression.FileSystem`) o `adm-zip`.
- **Sin hardware (`brs-node` / `brs-engine`):** `npx brs-cli --log-level debug canal.zip`.
  - El zip DEBE usar `/` en las rutas internas. **`Compress-Archive` de PowerShell las
    guarda con `\` y rompe `pkg:/`** — usar `adm-zip` de Node o `zip` de Git Bash/WSL.
  - Para detectar crashes, correr con timeout y redirigir: `timeout N npx brs-cli ... >
    out.log 2>&1` (Git Bash/WSL). **No** usar background sondeado con Read: el buffering de
    stdout da falsos negativos.
- **Tests:** no existen. `rasp/` son scripts de QA manual (aún referencian MiCHV).

## Arquitectura (lo no obvio)

- Entry point: `source/main.brs` → `MainScene`. `m.global` se arma una sola vez en
  `Global.brs::SetGlobalNode()` (`appConfig`/`appTheme`/`Fonts`/`apiEndPoints`).
- `MainScene` es un **router manual**: por página hay `ShowXPage()`/`GetXPageObject()`;
  la pila la maneja `ViewStackManager`. El back se centraliza en `MainScene.HandleBackKey()`.
- **Red siempre vía Task nodes** (`components/tasks/*`), nunca directo desde la página:
  setear `functionName`+`params`, observar `result`, `control = "RUN"`.
- Capa API en dos niveles: `BaseRequests.brs` (HTTP crudo sobre `roUrlTransfer`) +
  `ContentAPI.brs` (endpoints concretos).
- Deep link: `contentId` = `clave=valor` separado por `|`; parseo en
  `MainScene.splitDeeplinkingData()`. Tipos: movie/season/episode/series/live.

## Gotchas que ya costaron bugs reales

- **`setFields()` descarta en silencio** campos no declarados en el `.xml` del ItemNode —
  declarar todo campo nuevo.
- **Fuentes:** solo usar tamaños existentes en `FontManager.brs` (`dmSansBold18/20/23/28/30/32/36/48`).
  Asignar un `m.fonts.dmSansXxxNN` inexistente = `invalid` → crash `createDrawFont is not a function`.
- **`RowList`:** `itemSize` es el **viewport visible**, no el tamaño de item (reducirlo rompe
  el paginado horizontal); la animación de foco *dentro* de la fila es `rowFocusAnimationStyle`
  (no `horizFocusAnimationStyle`, que no existe y se ignora en silencio); `rowLabelOffset` es
  array-de-pares `[[x,y]]`.
- **Layout:** no adivines offsets en píxeles; medir con `boundingRect()` (fuentes/line-height
  reales del Roku no coinciden con la estimación). No "limpies" valores que parecen dead code
  sin poder probar el efecto en hardware.
- **Margen del sidebar:** las filas arrancan en `m.gDetails.translation = [106,0]`. Para
  full-bleed real hay que ser nodo fijo fuera del contenedor o contra-desplazar; no confundir
  "recortar ancho" con "desplazar".
- **Shapes del feed:** `destacados`/`masvistos` vienen envueltos `{data:[...]}` (dos niveles
  tras el wrapper de `handleApiResponse()`); `senales`/`radios` son arrays planos.
- **Home:** casi todo bug de layout/foco sale de `HomePage.brs` + `HomePageParser.brs` +
  el control de la fila (`SliderView`, `HeroSlider`, `MonumentalCard`).
