# Changelog

Cambios relevantes de este repositorio. El formato sigue
[Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

Las entradas se agrupan por fecha y no por número de versión: lo que se publica acá es un andamiaje
didáctico que se lee y se corre entero, no un artefacto que alguien instala en una versión
determinada. Este archivo arranca el 2026-09-03; lo anterior se lee en el historial de commits.

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
