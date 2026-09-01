namespace WebBlazor.E2E.Base.Login.E2ETests;

[Parallelizable(ParallelScope.Self)]
[TestFixture]
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
