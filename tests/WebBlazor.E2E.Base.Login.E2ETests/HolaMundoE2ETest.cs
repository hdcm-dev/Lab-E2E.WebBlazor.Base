
//para Coockie
using Microsoft.Playwright;

namespace WebBlazor.E2E.Base.Login.E2ETests;



[Parallelizable(ParallelScope.Self)]
[TestFixture]
internal class HolaMundoE2ETest : PageTest
{
    string CookieDeSesion = "MiCookie";

    static string UrlBase = "https://localhost:7212";

    [SetUp]
    async public Task Setup()
    {
        await Context.AddCookiesAsync(
        [
            new Cookie
            {
                Name = CookieDeSesion,
                Value = Guid.NewGuid().ToString("n"),
                Url = UrlBase
            }
        ]);
    }

    [SetUp]
    public async Task Setup()
    {
        await Page.GotoAsync("https://localhost:7071/HolaMundo");
        await Page.GotoAsync("/HolaMundo");
        await Expect(Page.GetByTestId("estado-app")).ToHaveAttributeAsync("data-interactivo", "true");
    }

    [Test]
    [Description("Mostrar Mensaje de texto")]
    public async Task MostrarMensaje()
    {
        string frase = "Hola mundo! - que tal?";

        await Page.GetByTestId("campo-frase").FillAsync(frase);
        await Page.GetByTestId("boton-mostrar-frase").ClickAsync();
        //await Expect(Page.GetByTestId("campo-mensaje")).ToHaveValueAsync(frase);
        await Expect(Page.GetByTestId("campo-mensaje")).ToHaveTextAsync(frase);
    }
}
