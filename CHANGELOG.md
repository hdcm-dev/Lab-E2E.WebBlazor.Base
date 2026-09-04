# Changelog

Cambios relevantes de este repositorio. El formato sigue
[Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

Las entradas se agrupan por fecha y no por número de versión: lo que se publica acá es un andamiaje
didáctico que se lee y se corre entero, no un artefacto que alguien instala en una versión
determinada. Este archivo arranca el 2026-09-03; lo anterior se lee en el historial de commits.

## [Sin publicar] - 2026-09-04

### Añadido

- **`tests/WebBlazor.E2E.Base.Login.E2ETests/LoginE2ETests.cs`** — nueve casos sobre la superficie
  de acceso y el guard que la rodea: se pasa con la credencial correcta, se vuelve al destino
  pedido, un `returnurl` externo no se honra, el rechazo se dice con el texto del catálogo, el
  rechazo no distingue cuál de los dos campos falló, lo incompleto no se intenta, sin sesión hay
  rebote, el rebote sirve, y la salida revoca el paso.
- **`tests/WebBlazor.E2E.Base.Login.E2ETests/PruebaDeSuperficie.cs`** — la base común: cómo se abre
  el navegador y cómo se llega a un estado de sesión conocido. Solo lo que no dice nada sobre
  ningún caso en particular.
- **`Guides/Caso-HolaMundo-Page.MD`** y **`Guides/Caso-Login-Page.md`** — cómo se **diseña** el caso
  de cada superficie, que es lo que `E2E-Guides.md` no cubría: ahí está cómo se escribe una prueba,
  acá con qué criterios se decide qué probar. Se leen juntos: casi todo lo que cambia entre ellos
  se deriva de una sola diferencia —si la superficie abre circuito o no—. La interactiva necesita
  el testigo de hidratación; la de acceso es SSR estático, su formulario viaja por POST y las
  esperas de Playwright ya cubren las navegaciones.
- **`/IA/PROMPTs/IA.Prompts/Base/Estilo-Redaccion-Explicativo.md`** *(fuera de este repositorio)* —
  el estilo de estos dos documentos, destilado para que otros agentes lo repliquen en otro
  contexto: el patrón de exposición, la estructura numerada y citable, la voz, y la postura que
  distingue lo verificado de lo razonado y de lo supuesto. Los dos documentos de caso quedan
  declarados ahí como corpus de referencia, así que **cambiarlos de forma cambia el ejemplo**.

### Cambiado

- **Se distingue la promesa positiva de la negativa, y `Caso-Login-Page.md` desarrolla la suya.**
  Puestas al lado, las dos promesas no tienen la misma forma: la del Hola Mundo es acción →
  desenlace; la del acceso tiene dos mitades y **la segunda es negativa** —dice qué no se puede
  llegar a saber—. Las cinco preguntas dan lo mismo en las dos, porque el método no cambia con el
  dominio, pero la fila 5 delata el trabajo extra: esta promesa tiene **dos formas de ser falsa** y
  la segunda no se parece a un error. De ahí salen dos cosas que no estaban escritas. La primera:
  una promesa de acceso tiene **dos sujetos** —quien entra y quien está probando suerte—, y la
  mitad del adversario es la que se olvida; queda como regla reusable y anclada a las tres piezas
  del `src` que la sostienen. La segunda: una promesa negativa **no tiene estado** —no hay ningún
  bloque del marcado que diga «acá no filtré información»—, vive en que dos estados sean
  indistinguibles, y por eso se verifica comparando y no mirando. Eso convierte la técnica de §4.4
  en una consecuencia en vez de una astucia, y explica el modo de falla que hay que temer: una
  promesa positiva rota se nota porque algo no aparece; una negativa rota **no se nota nunca**,
  porque el sistema sigue funcionando —solo que además está contando algo—.
- **Se define «estado de una superficie», que faltaba.** Los estados **no son superficies
  distintas**: son representaciones distintas de la misma promesa, y la superficie es el marco que
  las ordena. El corte entre superficies es la promesa, no la apariencia, y se discrimina con una
  sola pregunta —¿cambia lo que la persona puede **esperar**, o solo lo que ve?—. Ese marco no es
  una metáfora: está hecho código en dos piezas, el vocabulario de `EstadoDeSuperficie.cs` y el
  `@if / else if / else` de las líneas 87–110. Queda anotado por qué los estados no son cosméticos
  —dos son distintos cuando la salida que se le ofrece a la persona es distinta, que es lo que el
  `<remarks>` del enum ya decía sobre `Vacio` y `FiltradoSinResultados`—, las tres cosas que se
  confunden con un estado —situación y variante no lo son—, y cuáles de los estados merecen caso
  propio: `Enviando` no, porque afirmarlo obliga a atrapar un instante y ahí nacen las pruebas
  intermitentes.
- **La definición de «superficie» queda anclada al archivo real.** Decía qué es una superficie
  —lo que la persona ve, lo que puede hacer y en qué estados puede quedar— sin señalar dónde está
  cada una de esas tres partes, así que se entendía al leerla y no se sabía aplicarla. Ahora cada
  parte apunta a su rango de líneas en `HolaMundo.razor`, y una segunda tabla ancla lo que la
  definición **excluye**: los componentes, el chrome y la ruta. Se suma el criterio de corte —el
  conjunto más chico de marcado con una promesa propia verificable de punta a punta— y la relación
  con los otros artefactos que hablan de «la pantalla»: la historia dice *por qué*, el caso de uso
  dice *por dónde* y aporta sus flujos alternos, la maqueta dice *cómo se ve* y casi siempre dibuja
  un solo estado —de ahí que falten el vacío, el de carga y el de error—, y la superficie es el
  corte donde eso se vuelve observable. Con las cardinalidades, que es donde se rompe la intuición
  de «una historia, una pantalla, una prueba».
- **Los dos documentos de caso pasan a exponerse por preguntas.** Cada criterio abre con la
  pregunta que alguien realmente se hace —«¿Y si igual hago clic antes de tiempo?»—, sigue con la
  respuesta en una línea y cierra con ejemplos contrastados. Un ejemplo correcto aislado no enseña
  dónde está el límite; el par ✅/❌ sí, y el ⚠️ intermedio cubre el caso *cierto pero insuficiente*,
  que es el que más se repite en la práctica. `Caso-HolaMundo-Page.MD` suma además §2.2 —las cinco
  preguntas que se le hacen a una promesa—, §2.3 y §2.4 —seis superficies que las pasan y seis que
  no, cada una con qué falla y qué hacer— y §4.5 —cuándo hace falta un testigo y cuándo no, porque
  `InteractiveServer` no lo implica por sí solo—.
- **La solución se pone al día con lo que hay en el árbol.** `Ejemplos.WebBlazor.E2E.Base.slnx`
  suma los dos documentos nuevos a la carpeta `/Guides/`. La solución declara los archivos sueltos
  uno por uno, así que un documento que no se agrega existe en el repositorio pero no en el
  explorador de quien abre la solución: queda escrito y sin leer.
- **`HolaMundoE2ETest`** pasa a apoyarse en `PruebaDeSuperficie`, y el `Using` global de
  `Microsoft.Playwright` se declara en el csproj junto a los que ya estaban, en vez de repetir el
  `using` en cada archivo.

### Encontrado, no resuelto

- **El `<NotAuthorized>` de `Routes.razor` es camino muerto** para las páginas con `[Authorize]`.
  El caso 7 se escribió afirmando `/login?estado=sesion-requerida` —lo que produce el
  `<Redireccion>`— y falló: la aplicación produce `/login?returnurl=%2FHolaMundo`. La capa del
  guard que efectivamente actúa es el middleware de cookies, con su `LoginPath` y su
  `ReturnUrlParameter`, que corta antes de que el `Router` evalúe su `<NotAuthorized>`. De ahí que
  la entrada `SesionRequerida` del catálogo —«Ingresá para ver esa superficie.»— nunca se le muestre
  a nadie. Las pruebas se ajustaron a lo que la aplicación hace: corregir el comportamiento es una
  decisión de diseño y no la toma la prueba.

## [Sin publicar] - 2026-09-03

### Añadido

- **Testigo de hidratación** en las dos superficies `HolaMundo.razor`: un
  `data-testid="estado-app"` con `data-interactivo`, que arranca en `false` en el HTML del servidor
  y pasa a `true` desde `OnAfterRender`. Cierra la intermitencia registrada el 2026-09-02. La
  superficie llega pintada antes de que el circuito abra, y en esa ventana el botón existe, es
  visible, está habilitado y está quieto —las cuatro condiciones que Playwright verifica antes de
  un clic—, pero no responde. Playwright hace clic, nadie lo escucha, y no reintenta: el fracaso
  aparece después, en la aserción, con un mensaje que habla de otra cosa. `OnAfterRender` solo corre
  del lado del circuito, así que el atributo no promete la interactividad, la prueba. Las dos
  pruebas esperan ese estado antes de actuar, con un `Expect` —que sí reintenta— en el `[SetUp]`.
  El capítulo *El testigo de hidratación* de `Guides/E2E-Guides.md` lo explica entero.
- **`evidencia/2026-09-03-testigo-de-hidratacion/corrida.log`** — **0 de 8 corridas en rojo** en
  cada proyecto, 16 de 16 en verde, contra el 1 de 8 del 2026-09-02.

- **Contenedor de pruebas** en `.devcontainer/`: `Dockerfile` sobre la imagen oficial de Playwright
  —que ya trae las librerías de sistema de los navegadores— más el SDK de .NET 10 y `libnss3-tools`.
  Ese último no es un detalle: sin `certutil`, `dotnet dev-certs https --trust` no puede escribir en
  el almacén NSS que usa Chromium y la prueba muere en el handshake TLS, antes de la primera
  aserción. El `devcontainer.json` monta el repositorio en `/trabajo` y deja el `HOME`, los paquetes
  de NuGet y los navegadores dentro del árbol, para no ensuciar el host.
- **`scripts/pruebas.sh`** — corre las E2E sin instalar nada en el host: solo hace falta Docker.
  Construye la imagen si falta, compila, baja los navegadores, emite el certificado de desarrollo y
  lo carga con confianza `P,,` —el certificado concreto, no autoridad: es de entidad final
  (`CA:FALSE`) y declararlo autoridad hace que Chromium lo rechace con `ERR_CERT_INVALID`—, levanta
  la aplicación en la URL que la prueba tiene escrita en el código y corre `dotnet test`. Acepta
  `holamundo` (por defecto) o `login`, y `REPETIR=n` para buscar intermitencias.
- **`evidencia/2026-09-02-contenedor-de-pruebas/corrida.log`** — la corrida que justifica el
  `REPETIR`: **1 de 8 corridas en rojo**. La que falla es la primera, con
  `Locator expected to have text 'Hola mundo! - que tal?' But was: <element(s) not found>`; las
  otras siete pasan en menos de un segundo. La intermitencia queda registrada, no resuelta.
- **`Guides/Notas.GitHub.md`** — notas sobre la configuración del runner: el repositorio es público
  y los jobs corren en `i7infra-dev`, así que un PR desde un fork ejecutaría código sin revisar en
  esa máquina. Queda anotada la opción de *Require approval for fork pull request workflows*.

### Cambiado

- **`tests/WebBlazor.E2E.Base.Login.E2ETests/HolaMundoE2ETest.cs`** — el proyecto de pruebas del
  Login pasa a compilar y a correr en verde. Tenía dos `[SetUp]` con el mismo nombre; fabricaba a
  mano una cookie `MiCookie` con un GUID, que no podía autenticar nada —la sesión real es la cookie
  `auth_token`, `HttpOnly` y **firmada por el servidor**—; navegaba a `7071`, que es la URL del otro
  proyecto; y esperaba un `estado-app` que el marcado nunca declaró. Ahora el ingreso se hace por la
  superficie —que es el circuito que la aplicación ofrece— y la cookie la emite el servidor al
  aceptar el POST. La URL base y el `IgnoreHTTPSErrors` del certificado de desarrollo se declaran
  una sola vez, en `ContextOptions()`. La clase pasa de `internal` a `public`, que es como NUnit
  descubre los casos.

- **`.gitignore`** ignora los artefactos que deja el contenedor de pruebas dentro del árbol:
  `.contenedor-home/`, `.nuget/` y `.navegadores/`.

- **La solución se pone al día con lo que hay en el árbol.**
  `Ejemplos.WebBlazor.E2E.Base.slnx` seguía declarando `Guides/GitHub-Action.md`, que ya no existe
  —quedaba como enlace roto en Visual Studio—, y no declaraba `Guides/Notas.GitHub.md`, que lo
  reemplaza. Se suman además los archivos que nunca habían estado: `README.md` y `CHANGELOG.md` en
  un nodo `Solution Items`, y `scripts/pruebas.sh` en el suyo, que es el punto de entrada para
  correr las pruebas y hasta ahora había que buscarlo por fuera del explorador.

### Pendiente

- `tests/WebBlazor.E2E.Base.Login.E2ETests` **no compila**: dos métodos `[SetUp]` en la misma clase.
  `scripts/pruebas.sh login` lo dice antes de intentarlo.
