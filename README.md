# Lab-E2E.WebBlazor.Base

Proyectos base para practicar pruebas E2E con Playwright sobre Blazor Web App
(.NET 10, render mode Interactive Server).

| Proyecto | Qué demuestra |
| --- | --- |
| `src/WebBlazor.E2E.Base.HolaMundo` | Una superficie interactiva con sus estados y los identificadores de prueba declarados en el marcado |
| `src/WebBlazor.E2E.Base.Login` | Lo mismo detrás de un acceso: ingreso y cierre de sesión por POST fuera del circuito, con el guard en sus tres capas |

Los dos están construidos con el template por defecto del Framework SDD: tokens del
catálogo en `wwwroot/css/Tokens.css`, clases `mq-`, componentes propios uno por
patrón y ninguna librería de componentes. El detalle de qué se aplicó, qué se decidió
al aplicarlo y cómo se verificó está en
[`Guides/Template-SDD-Aplicado.md`](Guides/Template-SDD-Aplicado.md); la evidencia de
la corrida, en [`evidencia/2026-09-01-aplicacion-template/`](evidencia/2026-09-01-aplicacion-template/).

## Guías

- [`Guides/E2E-Guides.md`](Guides/E2E-Guides.md) — cómo se escriben y se corren las pruebas.
- [`Guides/Caso-HolaMundo-Page.MD`](Guides/Caso-HolaMundo-Page.MD) — cómo se diseña el caso de
  una superficie **interactiva**, y por qué necesita un testigo de hidratación.
- [`Guides/Caso-Login-Page.md`](Guides/Caso-Login-Page.md) — cómo se diseña el caso de una
  superficie **SSR** detrás de un acceso, y por qué ahí el testigo no hace falta.
- [`Guides/Marco-La-Superficie-Verificable.md`](Guides/Marco-La-Superficie-Verificable.md) — el marco conceptual de los dos
  anteriores: de qué tradición viene cada concepto —especificación formal, diseño de
  interacción, prueba automatizada—, con bibliografía y con lo que reinventamos sin saberlo.
- [`Guides/GitHub-Action.md`](Guides/GitHub-Action.md) — la corrida en CI.
- [`Guides/Template-SDD-Aplicado.md`](Guides/Template-SDD-Aplicado.md) — la forma constructiva de las superficies.
