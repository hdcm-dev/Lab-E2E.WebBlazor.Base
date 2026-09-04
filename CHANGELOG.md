# Changelog

Cambios relevantes de este repositorio. El formato sigue
[Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

Las entradas se agrupan por fecha y no por número de versión: lo que se publica acá es un andamiaje
didáctico que se lee y se corre entero, no un artefacto que alguien instala en una versión
determinada. Este archivo arranca el 2026-09-03; lo anterior se lee en el historial de commits.

## [Sin publicar] - 2026-09-03

### Añadido

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

- **`.gitignore`** ignora los artefactos que deja el contenedor de pruebas dentro del árbol:
  `.contenedor-home/`, `.nuget/` y `.navegadores/`.

### Pendiente

- `tests/WebBlazor.E2E.Base.Login.E2ETests` **no compila**: dos métodos `[SetUp]` en la misma clase.
  `scripts/pruebas.sh login` lo dice antes de intentarlo.
