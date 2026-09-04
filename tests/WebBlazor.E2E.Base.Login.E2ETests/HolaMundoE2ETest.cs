// `BrowserNewContextOptions` vive acá; el csproj solo declara global el de `.NUnit`.
using Microsoft.Playwright;

namespace WebBlazor.E2E.Base.Login.E2ETests;

/// <summary>
/// Lo que este proyecto agrega sobre el HolaMundo base es una sola cosa: la
/// superficie está detrás de un acceso. Por eso el caso de prueba es el mismo, y
/// lo único que cambia es cómo se llega al estado conocido del que parte.
/// </summary>
[Parallelizable(ParallelScope.Self)]
[TestFixture]
public class HolaMundoE2ETest : PageTest
{
    private const string UrlBase = "https://localhost:7212";

    // El certificado de desarrollo no lo valida el navegador de Playwright.
    public override BrowserNewContextOptions ContextOptions() =>
        new() { IgnoreHTTPSErrors = true, BaseURL = UrlBase };

    // Iniciar en estado conocido: la pantalla abierta y con la sesión establecida.
    // El ingreso se hace por la superficie, que es el circuito que la aplicación
    // ofrece; la cookie de sesión la emite el servidor al aceptar el POST y el
    // contexto del navegador la conserva. No se fabrica acá: una cookie inventada
    // no está firmada y el guard la rechaza.
    [SetUp]
    public async Task Setup()
    {
        await Page.GotoAsync("/login");
        await Page.GetByTestId("campo-usuario").FillAsync("admin");
        await Page.GetByTestId("campo-clave").FillAsync("admin");
        await Page.GetByTestId("boton-ingresar").ClickAsync();

        await Page.GotoAsync("/HolaMundo");

        // La superficie llega pintada antes de que el circuito abra, y en esa ventana
        // el botón se ve y se puede clickear pero no responde. `Expect` reintenta:
        // la prueba queda detenida hasta que la superficie declara que ya es interactiva.
        await Expect(Page.GetByTestId("estado-app"))
            .ToHaveAttributeAsync("data-interactivo", "true");
    }

    [Test]
    [Description("Mostrar Mensaje de texto")]
    public async Task MostrarMensaje()
    {
        string frase = "Hola mundo! - que tal?";

        await Page.GetByTestId("campo-frase").FillAsync(frase);
        await Page.GetByTestId("boton-mostrar-frase").ClickAsync();
        await Expect(Page.GetByTestId("campo-mensaje")).ToHaveTextAsync(frase);
    }
}
