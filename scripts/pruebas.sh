#!/usr/bin/env bash
# Corre las pruebas E2E de este repositorio sin instalar nada en el host: ni SDK, ni navegadores,
# ni certificado de desarrollo. Solo hace falta Docker.
#
#   scripts/pruebas.sh                 # proyecto holamundo (por defecto)
#   scripts/pruebas.sh holamundo
#   scripts/pruebas.sh login           # hoy no compila: dos [SetUp] en la misma clase
#   REPETIR=5 scripts/pruebas.sh       # corre la batería 5 veces seguidas (buscar intermitencias)
#
# Qué hace, en orden:
#   1. construye la imagen `.devcontainer/Dockerfile` si todavía no existe;
#   2. compila la aplicación y el proyecto de pruebas;
#   3. descarga los navegadores de Playwright en `.navegadores/` (solo la primera vez);
#   4. emite el certificado de desarrollo y lo carga en el almacén NSS que usa Chromium;
#   5. levanta la aplicación en la URL que la prueba tiene escrita en el código;
#   6. corre `dotnet test` y apaga la aplicación.
#
# Sobre el paso 4: el certificado se agrega con confianza `P,,` —«peer», el certificado concreto—
# y no con `C,,` —«autoridad»—. El certificado de desarrollo de ASP.NET es de entidad final
# (`CA:FALSE`), así que declararlo autoridad hace que Chromium lo rechace con ERR_CERT_INVALID.
#
# Sobre el paso 5: la URL no se elige acá, se copia de lo que la prueba espera. Mientras el proyecto
# de pruebas tenga la URL escrita en el código, cambiarla de un lado obliga a cambiarla del otro.
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGEN="${IMAGEN_E2E:-lab-e2e-base-dev:net10}"
PROYECTO="${1:-holamundo}"
REPETIR="${REPETIR:-1}"

case "$PROYECTO" in
  holamundo)
    APP="src/WebBlazor.E2E.Base.HolaMundo"
    PRUEBAS="tests/WebBlazor.E2E.Base.HolaMundo.E2ETests"
    # HolaMundoE2ETests.cs:10 — el literal de la prueba, no el perfil de launchSettings (7230).
    URL_APP="${URL_APP:-https://localhost:7071}"
    ;;
  login)
    APP="src/WebBlazor.E2E.Base.Login"
    PRUEBAS="tests/WebBlazor.E2E.Base.Login.E2ETests"
    # HolaMundoE2ETest.cs:15 declara 7212 y la línea 34 navega a 7071: hoy no coinciden.
    URL_APP="${URL_APP:-https://localhost:7212}"
    ;;
  *)
    echo "Proyecto desconocido: $PROYECTO (esperaba 'holamundo' o 'login')" >&2
    exit 2
    ;;
esac

if ! docker image inspect "$IMAGEN" >/dev/null 2>&1; then
  echo "== Construyendo la imagen $IMAGEN (solo la primera vez) =="
  docker build -t "$IMAGEN" -f "$RAIZ/.devcontainer/Dockerfile" "$RAIZ/.devcontainer"
fi

exec docker run --rm --ipc=host \
  --user "$(id -u):$(id -g)" \
  --env HOME=/trabajo/.contenedor-home \
  --env NUGET_PACKAGES=/trabajo/.nuget \
  --env PLAYWRIGHT_BROWSERS_PATH=/trabajo/.navegadores \
  --env DOTNET_CLI_TELEMETRY_OPTOUT=1 \
  --env DOTNET_NOLOGO=1 \
  --env APP="$APP" \
  --env PRUEBAS="$PRUEBAS" \
  --env URL_APP="$URL_APP" \
  --env REPETIR="$REPETIR" \
  --volume "$RAIZ:/trabajo" \
  --workdir /trabajo \
  "$IMAGEN" bash -c '
set -euo pipefail
export SSL_CERT_DIR="$HOME/.aspnet/dev-certs/trust:/usr/lib/ssl/certs"

echo "== Compilando =="
dotnet build "$APP"     --configuration Debug --nologo --verbosity quiet
dotnet build "$PRUEBAS" --configuration Debug --nologo --verbosity quiet

SALIDA="$PRUEBAS/bin/Debug/net10.0"
if [ ! -d /trabajo/.navegadores ]; then
  echo "== Descargando los navegadores en .navegadores/ (solo la primera vez) =="
  # Equivale a `playwright.ps1 install`, sin necesitar PowerShell dentro del contenedor.
  "$SALIDA/.playwright/node/linux-x64/node" "$SALIDA/.playwright/package/cli.js" install chromium
fi

echo "== Certificado de desarrollo =="
mkdir -p "$HOME/.pki/nssdb"
# Crear la base NSS solo si no existe: `certutil -N` sobre una base ya creada se queda esperando
# una contraseña por consola y cuelga la corrida, aun con la entrada estándar cerrada.
if [ ! -f "$HOME/.pki/nssdb/cert9.db" ]; then
  certutil -d sql:"$HOME/.pki/nssdb" -N --empty-password </dev/null
fi
dotnet dev-certs https --export-path /tmp/aspnet-dev.pem --format PEM </dev/null >/dev/null
certutil -d sql:"$HOME/.pki/nssdb" -D -n aspnet-dev </dev/null >/dev/null 2>&1 || true
certutil -d sql:"$HOME/.pki/nssdb" -A -t "P,," -n aspnet-dev -i /tmp/aspnet-dev.pem </dev/null

echo "== Levantando la aplicación en $URL_APP =="
ASPNETCORE_URLS="$URL_APP" ASPNETCORE_ENVIRONMENT=Development \
  dotnet run --project "$APP" --no-launch-profile --no-build > /tmp/aplicacion.log 2>&1 &
PID_APP=$!
trap "kill $PID_APP 2>/dev/null || true" EXIT

for _ in $(seq 1 60); do
  curl -sk "$URL_APP/" -o /dev/null 2>/dev/null && break || sleep 1
done
if ! curl -sk "$URL_APP/" -o /dev/null 2>/dev/null; then
  echo "La aplicación no respondió. Log:" >&2
  tail -20 /tmp/aplicacion.log >&2
  exit 1
fi

FALLAS=0
for N in $(seq 1 "$REPETIR"); do
  [ "$REPETIR" -gt 1 ] && echo "== Corrida $N de $REPETIR =="
  dotnet test "$PRUEBAS" --no-build --nologo || FALLAS=$((FALLAS + 1))
done

[ "$REPETIR" -gt 1 ] && echo "== Resumen: $FALLAS de $REPETIR corridas en rojo =="
exit $([ "$FALLAS" -eq 0 ] && echo 0 || echo 1)
'
