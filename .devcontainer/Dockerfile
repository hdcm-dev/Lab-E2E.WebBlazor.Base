# Imagen para correr las pruebas E2E sin instalar nada en el host.
#
# Parte de la imagen oficial de Playwright, que ya trae las librerías de sistema que los
# navegadores necesitan (la parte difícil de reproducir a mano), y le agrega:
#   - el SDK de .NET 10, que la imagen no trae;
#   - certutil (libnss3-tools), para que `dotnet dev-certs https --trust` pueda escribir en el
#     almacén NSS que usa Chromium: sin eso el navegador rechaza el certificado de desarrollo
#     y la prueba muere en el handshake TLS, antes de la primera aserción.
#
# La versión de la imagen no tiene que coincidir con la del paquete Microsoft.Playwright del
# proyecto: los navegadores los descarga el proyecto en `.navegadores/`, y de la imagen se
# aprovechan las librerías del sistema.
FROM mcr.microsoft.com/playwright:v1.62.1-noble

ARG CANAL_DOTNET=10.0
ENV DOTNET_ROOT=/usr/share/dotnet \
    PATH=/usr/share/dotnet:$PATH \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    ASPNETCORE_ENVIRONMENT=Development

RUN apt-get update \
 && apt-get install -y --no-install-recommends libnss3-tools curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
 && bash /tmp/dotnet-install.sh --channel "${CANAL_DOTNET}" --install-dir "${DOTNET_ROOT}" --no-path \
 && rm /tmp/dotnet-install.sh \
 && chmod -R a+rx "${DOTNET_ROOT}"

# La imagen de Playwright trae el usuario `pwuser`; se trabaja con él y no con root para que los
# archivos que genera el contenedor queden con dueño razonable en el volumen montado.
WORKDIR /trabajo
