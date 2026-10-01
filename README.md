# 13GO — canal Roku

Canal Roku (BrightScript/SceneGraph) de 13go (Canal 13, Chile). Detalle del proyecto,
arquitectura y estado en [CLAUDE.md](CLAUDE.md).

## Clave de firma (para empaquetar el .pkg)

Son las claves de los canales 13GO ya publicados (vienen de la app anterior,
`roku_13go_old`). Para que este canal salga como actualización del publicado, el
paquete tiene que firmarse con la misma clave: en el Roku de empaquetado,
*Utilities → Rekey* con el paquete firmado anterior y su contraseña (`genkey` solo
si se crea un canal nuevo).

Canal publicado:

    Password: YgMpafUPkb5GnYfF6hIc9A==
    DevID: 0c150a922cddd81779480c744670601befedee95

Canal beta:

    Password: 7WeS4vPyDByUFw7CPb0VdQ==
    DevID: e1cd96a17e03da8b3735824d66f0ea3b363bb09e

La versión del `manifest` tiene que ser mayor que la publicada (la app anterior llegó
a la 11.4; este canal arranca en la 12.0).

## Deep linking

Se aceptan dos formatos (`contentId` + `mediaType`).

Rutas de 13go.cl (con o sin dominio):

    series   /programas/betty-la-fea
    episode  /programas/betty-la-fea/capitulos/{capitulo}
    live     /en-vivo?sid=13go1   (o solo la key: 13go1)

Formato de la app anterior (compatibilidad con links ya guardados en Roku):

    series   533                (id numérico del programa, feed/programa/{id})
    episode  533|455553         (programa|capítulo)
    live     t13                (key de la señal)
    live     radio|SonarFM      (radio por nombre)

Prueba en un Roku en modo desarrollador:

    curl -d "" "http://<ip>:8060/launch/dev?contentId=533&mediaType=series"

## Sideload

Comprimir `manifest`, `components/`, `fonts/`, `images/` y `source/` en un zip (con
rutas internas `/`, no `\`) y subirlo en `http://<ip-del-roku>` (Development
Application Installer). Log en vivo: telnet al puerto 8085.
