# Caso de prueba: la superficie Hola Mundo

**Superficie:** `Components/Paginas/HolaMundo.razor`
**Prueba:** `tests/WebBlazor.E2E.Base.HolaMundo.E2ETests/HolaMundoE2ETests.cs`
**Qué tipo de superficie es:** interactiva (`@rendermode InteractiveServer`)

Este documento no explica *cómo se escribe* una prueba con Playwright —eso está en
[`E2E-Guides.md`](E2E-Guides.md)—, sino **cómo se decide qué probar** en una
superficie como esta, y por qué el caso quedó como quedó.

---

## 1. Definiciones

Tres términos que se usan todo el tiempo más abajo. Conviene fijarlos primero.

### 1.1 Superficie

**La pantalla como unidad de diseño**: lo que la persona ve, lo que puede hacer y en
qué estados puede quedar. No es «el componente» ni «la página»: un componente es una
pieza de implementación, y una superficie es una promesa hecha a alguien.

### 1.2 Circuito

**La conexión WebSocket entre el navegador y el servidor** que hace que una
superficie Blazor Server reaccione. Los manejadores —`@onclick`, `@bind-Value`— no
viven en el navegador: viven en el servidor, del otro lado del circuito.

### 1.3 Identificador de prueba

**Un `data-testid` declarado en el marcado, junto al control que nombra.** Es un
nombre estable y explícito, puesto ahí *para* que la prueba lo use. La alternativa
—buscar por clase CSS o por posición— ata la prueba a decisiones de presentación que
cambian sin aviso.

```razor
<InputText id="campo-frase" data-testid="campo-frase" class="mq-input"
           @bind-Value="_modelo.Frase" />
```

---

## 2. Qué promete esta superficie

Antes de escribir una prueba hay que poder decir en una frase qué promete la pantalla.
Si no se puede, no está lista para probarse.

> **Escribo una frase, la muestro, y la frase aparece.**

Eso es todo. La superficie no consulta ningún servicio, no persiste nada y no navega
a ningún lado. Es deliberadamente pobre: existe para que el andamiaje de la prueba se
vea sin ruido alrededor.

---

## 3. Los criterios de diseño del caso

### 3.1 Se prueba la promesa, no la implementación

La prueba escribe, acciona y verifica **lo que la persona vería**. No inspecciona el
campo privado `_mensaje`, no cuenta renders, no mide el circuito. Si mañana la frase
se guardara en una base de datos, la prueba no debería enterarse: la promesa no cambió.

### 3.2 El caso tiene tres partes, y una es el punto de partida

| Parte | Dónde va | Qué hace |
| --- | --- | --- |
| **Iniciar** | `[SetUp]` | Deja la pantalla en un **estado conocido** |
| **Actuar** | `[Test]` | Hace la acción que la superficie ofrece |
| **Verificar** | `[Test]` | Afirma el desenlace observable |

El `[SetUp]` no es un trámite. Es la parte que declara *desde dónde* parte el caso, y
cuando esa declaración es floja, la prueba se vuelve intermitente.

### 3.3 Un identificador por control que la prueba toca

Y solo por esos. Un `data-testid` en cada elemento sería ruido; los tres que hay
—`campo-frase`, `boton-mostrar-frase`, `campo-mensaje`— son exactamente los que el
caso necesita nombrar.

### 3.4 El elemento verificado contiene el mensaje y nada más

```razor
<p class="mq-kv__valor mq-mt-2" data-testid="campo-mensaje">@_mensaje</p>
```

Si ese `<p>` tuviera además un rótulo o un ícono adentro, `ToHaveTextAsync` obligaría
a comparar contra un texto compuesto, y la aserción empezaría a depender de la
maqueta. Se mantiene atómico **para que la comparación pueda ser exacta**.

---

## 4. El criterio propio de una superficie interactiva

Este es el criterio que distingue a esta superficie de una estática, y es el único
verdaderamente difícil.

### 4.1 El problema: la superficie llega dos veces

Una superficie `InteractiveServer` no llega terminada. Llega **dos veces**:

| Momento | Qué hay | Qué se ve |
| --- | --- | --- |
| **1. La foto** | El HTML que armó el servidor, sin manejadores conectados | La pantalla completa |
| **2. La pantalla viva** | El circuito abierto; Blazor adoptó el marcado | La pantalla completa |

Se ven **idénticas**. Y entre una y otra pasan decenas o cientos de milisegundos.

Eso segundo es *hidratar*: el HTML llega deshidratado —con la forma correcta pero sin
nada corriendo adentro— y el circuito lo rehidrata.

### 4.2 Por qué eso rompe la prueba

Playwright, antes de cada clic, verifica cuatro cosas: que el elemento **exista**, sea
**visible**, esté **habilitado** y esté **quieto**. Si algo falta, espera y reintenta.

**En la ventana entre los dos momentos, las cuatro condiciones se cumplen.** El botón
está ahí, se ve, no está `disabled`, no se mueve. Playwright hace clic, nadie lo
escucha, y **no reintenta**: desde su punto de vista el clic salió bien.

El fracaso aparece después, en la aserción, con un mensaje que habla de otra cosa:

```
Locator expected to have text 'Hola mundo! - que tal?' But was: '<element(s) not found>'
```

Una persona nunca lo nota, porque tarda medio segundo en mover el mouse. Una máquina
hace clic en cuanto puede.

> **Este no es un riesgo teórico.** El `CHANGELOG` del 2026-09-02 registró esta misma
> intermitencia con ese mismo mensaje: **1 de 8 corridas en rojo**, y la que fallaba
> era siempre la primera —la que paga el arranque frío y estira la ventana—.

### 4.3 La solución: el testigo

> **Testigo:** un elemento del marcado cuyo único trabajo es **afirmar en el DOM un
> hecho que la prueba no puede deducir mirando la pantalla**.

Su condición de validez es una sola:

> **Solo lo puede escribir código que ya corre del lado del circuito.**

Por eso su presencia no es una promesa, es una **prueba**. No dice «debería estar
hidratado». Dice «esto se ejecutó, y esto solo se ejecuta si hay circuito».

En el marcado:

```razor
<span class="mq-sr-only" data-testid="estado-app" data-interactivo="@_interactivo"></span>

@code {
    // Arranca en `false` y así viaja en el HTML del servidor: el testigo dice que no
    // hay circuito hasta que lo haya.
    private string _interactivo = "false";

    // `OnAfterRender` solo corre del lado del circuito: si esto se ejecutó, la
    // superficie ya responde.
    protected override void OnAfterRender(bool primeraVez)
    {
        if (!primeraVez || _interactivo == "true") { return; }

        _interactivo = "true";
        StateHasChanged();
    }
}
```

Dos detalles que no son de adorno:

- **Arranca en `"false"`**, y ese valor viaja en la foto del servidor. Si el testigo
  apareciera recién al hidratar, «todavía no existe» y «no existe porque me equivoqué
  de nombre» serían indistinguibles.
- **Está fuera de la vista** (`mq-sr-only`), porque es un dato para máquinas. Las
  aserciones de atributo no necesitan que el elemento sea visible.

Y en el `[SetUp]`, una línea:

```csharp
await Expect(Page.GetByTestId("estado-app"))
    .ToHaveAttributeAsync("data-interactivo", "true");
```

**`Expect` sí reintenta**, a diferencia del clic. La carrera se convierte en una
espera con una condición explícita, y si algo se rompe de verdad, el error nombra el
problema real.

### 4.4 El agravante de este caso concreto

El botón es `type="submit"` dentro de un `<EditForm FormName="frase">`. Sin hidratar,
el clic **no es inerte**: dispara el envío HTML de toda la vida, la página se recarga
entera y el resultado difiere del esperado. No es que «no pasa nada»; es que pasa
otra cosa.

---

## 5. El caso, entero

```csharp
[Parallelizable(ParallelScope.Self)]
[TestFixture]
public class HolaMundoE2ETests : PageTest
{
    [SetUp]
    public async Task Setup()
    {
        await Page.GotoAsync("https://localhost:7071/HolaMundo");

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
```

---

## 6. Lo que este caso deliberadamente no prueba

Declararlo importa: una ausencia sin explicar se lee como olvido.

| No se prueba | Por qué |
| --- | --- |
| El **error de entrada** (frase vacía o de más de 120 caracteres) | Es un caso legítimo y todavía no está escrito. Queda anotado como pendiente, no como decisión. |
| El **estado vacío** inicial | El `[SetUp]` ya pasa por él; verificarlo aparte agregaría un caso que falla junto con el otro. |
| El **estado `Indisponible`** | No aplica: la frase no viaja a ningún servicio externo, así que no hay servicio que pueda no responder. |
| La **accesibilidad** (región activa, rótulos, foco) | Es otra clase de verificación, con otras herramientas. No se mezcla acá. |

---

## 7. Cómo se corre

```bash
scripts/pruebas.sh holamundo      # una corrida
REPETIR=8 scripts/pruebas.sh holamundo   # ocho, para buscar intermitencias
```

El `REPETIR` no es un lujo. **Una prueba de concurrencia que pasó una vez no probó
nada**: fue así como la intermitencia de la hidratación quedó registrada, y fue así
como se comprobó que el testigo la cerraba —16 de 16 en verde, en
[`evidencia/2026-09-03-testigo-de-hidratacion/`](../evidencia/2026-09-03-testigo-de-hidratacion/)—.

---

## 8. El criterio, en una línea

> **Lo que la prueba necesita nombrar, se declara en el marcado.**

Vale para los controles —`campo-frase`, `campo-mensaje`— y vale igual para los
estados —`estado-app`—. Lo que la prueba tiene que adivinar, tarde o temprano lo
adivina mal.

---

## 9. Y en la superficie de al lado

La otra superficie de este laboratorio, la de acceso, **no lleva testigo**, y no es
un descuido: es SSR estático, sin circuito, y ahí el criterio cambia por completo.
Está en [`Caso-Login-Page.md`](Caso-Login-Page.md).
