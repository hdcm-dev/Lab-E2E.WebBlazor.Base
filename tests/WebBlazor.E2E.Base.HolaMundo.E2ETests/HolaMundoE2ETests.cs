namespace WebBlazor.E2E.Base.HolaMundo.E2ETests;

[Parallelizable(ParallelScope.Self)]
[TestFixture]
public class HolaMundoE2ETests : PageTest
{
    [SetUp]
    public async Task Setup()
    {
        await Page.GotoAsync("https://localhost:7071/HolaMundo");
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
