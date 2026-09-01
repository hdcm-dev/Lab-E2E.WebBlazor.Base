
using Microsoft.Playwright;

namespace WebBlazor.E2E.Base.HolaMundo.E2ETests;

internal class LoginE2ETests : PageTest
{
    string CookieDeSesion = "MiCookie";

    [SetUp]
    async public Task Setup()
    {
        await Context.AddCookiesAsync(
        [
            new Cookie
            {
                Name = CookieDeSesion,
                Value = Guid.NewGuid().ToString("n"),
                Url = ServidorDeLaAplicacion.UrlBase
            }
        ]);
    }

    [Test]
    [Description("Test de login")]
    public async Task TestLogin()
    {
        // Implement your login test logic here
        // For example, navigate to the login page, fill in credentials, and assert successful login
    }
}
