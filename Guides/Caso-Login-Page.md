# Caso de prueba: la superficie de acceso

**Superficie:** `Components/Paginas/Identidad/Ingreso.razor`
**Pruebas:** `tests/WebBlazor.E2E.Base.Login.E2ETests/LoginE2ETests.cs`
**Base común:** `tests/WebBlazor.E2E.Base.Login.E2ETests/PruebaDeSuperficie.cs`
**Qué tipo de superficie es:** SSR estático (**sin** `@rendermode`)

El caso hermano —la superficie interactiva— está en
[`Caso-HolaMundo-Page.MD`](Caso-HolaMundo-Page.MD). Conviene leer los dos juntos:
casi todo lo que cambia entre ellos se explica por una sola diferencia.

---

## 1. Definiciones

### 1.1 Guard

**Lo que decide si alguien pasa.** Acá está declarado en tres capas, y cada una corta
en un momento distinto:

| Capa | Dónde | Cuándo corta |
| --- | --- | --- |
| **Ruteo** | El middleware de autenticación, y el `<NotAuthorized>` de `Routes.razor` | Antes de resolver la superficie |
| **Superficie** | `OnInitializedAsync` de la página | Al abrirse el componente |
| **Acción** | El endpoint `POST /identidad/ingreso` | Al ejecutar la operación |

### 1.2 Credencial de sesión

**La cookie que el servidor emite y firma** al aceptar un ingreso. Acá se llama
`auth_token`, es `HttpOnly` y `SameSite=Strict`. Que esté **firmada** es lo que hace
imposible fabricarla desde afuera.

### 1.3 Rechazo indiferenciado

**Un solo desenlace para todas las formas de fallar.** «El identificador no existe» y
«el secreto no es» producen exactamente el mismo mensaje, porque distinguirlos le
confirma la existencia de una identidad a quien no debería saberlo.

### 1.4 Catálogo de resultados

**La tabla única de la que salen los mensajes que la persona lee.** Un código sin
entrada cae en el mensaje genérico, nunca en el código crudo ni en la traza.

---

## 2. Qué promete esta superficie

> **Con la credencial correcta se pasa; sin ella no, y lo que se dice al respecto no
> le enseña nada a quien está probando suerte.**

La segunda mitad de esa frase es lo interesante. Esta superficie no promete solo un
comportamiento: promete **un silencio**. Y un silencio también se prueba.

---

## 3. La diferencia que ordena todo el resto

Esta superficie **no lleva `@rendermode`**. Es SSR estático, y su formulario viaja por
POST a un endpoint.

### 3.1 Por qué está construida así

No es una preferencia de estilo. La credencial de sesión se emite **en el ciclo de
request**: con el circuito ya establecido, la respuesta HTTP ya se envió y **no hay
dónde escribir la cabecera que crea la cookie**. Un ingreso interactivo, en Blazor
Server, no puede funcionar.

### 3.2 Qué consecuencia tiene para la prueba

**No hay ventana de hidratación, así que no hay testigo que esperar.**

En la superficie interactiva, el problema central era que el botón se ve listo antes
de estarlo ([§4 del caso Hola Mundo](Caso-HolaMundo-Page.MD)). Acá ese problema no
existe: el `<form method="post">` es HTML nativo, funciona con el primer byte que
llega, y el envío es **una navegación** —de las que las esperas de Playwright ya
cubren por sí solas—.

> Esta es la lección que hace útil comparar los dos documentos: **el andamiaje de una
> prueba no se elige por gusto, se deriva de cómo está construida la superficie.**

| | Hola Mundo | Acceso |
| --- | --- | --- |
| Render | `InteractiveServer` | SSR estático |
| Cómo actúa | `@onclick` sobre el circuito | POST del navegador |
| ¿Ventana de hidratación? | **Sí** | No |
| ¿Testigo en el `[SetUp]`? | **Sí** | No hace falta |
| Estado del que parte | *Con* sesión | *Sin* sesión |

---

## 4. Los criterios de diseño de estos casos

### 4.1 Se afirma lo que la persona ve, nunca el mecanismo

**La prueba no mira la cookie.** Que la sesión exista se comprueba por su efecto:
poder ver la superficie protegida.

```csharp
// Así:
await Expect(Page).ToHaveURLAsync($"{UrlBase}/");
await Expect(Page.GetByRole(AriaRole.Heading, new() { Name = "Inicio" })).ToBeVisibleAsync();
```

Si mañana la sesión pasara a un token en otro lado, la promesa seguiría siendo la
misma y la prueba no debería enterarse.

De ahí sale también la regla inversa, y es la que más veces se rompe en la práctica:

> **Nunca se fabrica el estado que la prueba debería obtener actuando.**

El archivo del que salió esta clase intentaba justamente eso: inyectaba a mano una
cookie con un GUID. No podía funcionar —la sesión real la firma el servidor—, pero el
problema de fondo es anterior: **una prueba que fabrica su propio estado deja de
probar el camino por el que la persona pasa**. Aun si la cookie hubiese funcionado, el
circuito de ingreso habría quedado sin probar.

### 4.2 Se ingresa por la superficie, no por atajos

```csharp
protected async Task IngresarAsync(string? identificador = null, string? secreto = null)
{
    await Page.GetByTestId("campo-usuario").FillAsync(identificador ?? Identificador);
    await Page.GetByTestId("campo-clave").FillAsync(secreto ?? Secreto);
    await Page.GetByTestId("boton-ingresar").ClickAsync();
}
```

El método vive en la clase base porque **todas** las pruebas del proyecto lo
necesitan, incluida la de la superficie protegida, que lo usa solo para llegar a su
punto de partida.

Los parámetros son opcionales a propósito: quien llama sin argumentos dice «una
credencial válida, no me importa cuál»; quien pasa uno dice «esta credencial es
parte de lo que estoy probando». La firma del método distingue el trámite del caso.

### 4.3 El estado del que se parte es *sin sesión*

Y por eso el `[SetUp]` casi no hace nada:

```csharp
// El estado conocido del que parten estos casos es *sin sesión*, que es con lo
// que arranca todo contexto nuevo de Playwright. El [SetUp] solo abre la pantalla.
[SetUp]
public Task Setup() => Page.GotoAsync("/login");
```

Playwright le da a cada caso **un contexto de navegador propio**, con cookies y
almacenamiento nuevos. El aislamiento no hay que construirlo: viene puesto. Lo que sí
hay que hacer es **no romperlo**, y es lo que se rompe cuando se comparte sesión entre
casos para que corran más rápido.

### 4.4 Una propiedad negativa se prueba comparando, no mirando

El rechazo indiferenciado (§1.3) es una promesa de las difíciles: no dice qué debe
pasar, dice qué **no** debe poder deducirse. Mirando un solo desenlace no se ve nada.

La forma de probarla es **provocar dos fracasos distintos y comprobar que son
indistinguibles**:

```csharp
[Test]
[Description("El rechazo no dice cuál de los dos campos falló")]
public async Task ElRechazoNoDistingueQueCampoFallo()
{
    await IngresarAsync(identificador: "nadie");
    var conIdentificadorInexistente = await Page.GetByTestId("mensaje-resultado").TextContentAsync();

    await Page.GotoAsync("/login");
    await IngresarAsync(secreto: "lo-que-no-es");
    var conSecretoIncorrecto = await Page.GetByTestId("mensaje-resultado").TextContentAsync();

    Assert.That(conSecretoIncorrecto, Is.EqualTo(conIdentificadorInexistente));
}
```

Notá que **no se compara contra un texto literal**. Se comparan los dos desenlaces
entre sí. Si mañana el mensaje cambia, este caso sigue siendo válido: lo que afirma no
es *qué* dice, sino que **dice lo mismo en los dos casos**.

### 4.5 Se afirma la promesa, no el detalle reversible

```csharp
[Test]
[Description("Un destino externo no se honra: el ingreso no es una redirección abierta")]
public async Task UnDestinoExternoNoSeHonra()
{
    await Page.GotoAsync("/login?returnurl=https://ejemplo.invalido/");
    await IngresarAsync();

    // El caso se escribe desde la promesa —«de acá no se sale»— y no desde el
    // detalle de a qué ruta local se cae, que es una decisión reversible.
    await Expect(Page).ToHaveURLAsync(new Regex($"^{Regex.Escape(UrlBase)}/"));
}
```

La promesa es «un `returnurl` externo no convierte al ingreso en una redirección
abierta». Que el destino de repuesto sea `/` y no otra ruta local es una decisión que
alguien puede cambiar mañana con toda razón, y no debería poner una prueba en rojo.

**Regla práctica:** cuando dudes de cuánto afirmar, preguntate qué tendría que pasar
para que este caso falle *con razón*. Si la respuesta incluye un cambio inocente,
estás afirmando de más.

### 4.6 Cada caso falla por un motivo

Un caso que verifica el rebote del guard **y además** que después se llega al destino
falla por dos causas distintas, y el reporte no dice cuál. Se parten:

```csharp
[Test] public async Task LaSuperficieProtegidaExigeSesion() { ... }  // el rebote ocurre
[Test] public async Task ElDestinoSobreviveAlRebote()      { ... }  // el rebote sirvió
```

---

## 5. El mapa de los casos

Diez casos, y cada uno cubre un tramo distinto del circuito.

| # | Caso | Qué afirma |
| --- | --- | --- |
| 1 | `IngresoAceptadoAbreLaSuperficieDeTrabajo` | Con la credencial correcta, se pasa |
| 2 | `IngresoAceptadoVuelveAlDestinoPedido` | Se vuelve a donde se quería ir |
| 3 | `UnDestinoExternoNoSeHonra` | El ingreso no es una redirección abierta |
| 4 | `IngresoRechazadoVuelveAlAccesoConElMensajeDelCatalogo` | El rechazo se dice con el texto del catálogo |
| 5 | `ElRechazoNoDistingueQueCampoFallo` | El rechazo no enseña nada |
| 6 | `UnEnvioIncompletoNoSale` | Lo que falta no se intenta |
| 7 | `LaSuperficieProtegidaExigeSesion` | Sin sesión hay rebote, y se anota el destino |
| 8 | `ElDestinoSobreviveAlRebote` | El rebote sirvió para algo |
| 9 | `CerrarLaSesionRevocaElPaso` | La salida surte efecto |
| 10 | `MostrarMensaje` *(en `HolaMundoE2ETest`)* | La superficie protegida funciona una vez adentro |

### 5.1 Cómo se eligieron

No por cobertura de líneas. Cada uno sale de **una frase que la superficie promete**,
y el conjunto se cierra cuando ninguna promesa queda sin caso. Las promesas están en
el marcado y en los comentarios de diseño del `src`: `Ingreso.razor` dice que el
rechazo es indiferenciado, `IdentidadEndpoints.cs` dice que solo se admiten rutas
locales. **Cada una de esas afirmaciones es un caso esperando a ser escrito.**

---

## 6. Un hallazgo que apareció al escribir estos casos

Vale dejarlo anotado, porque ilustra para qué sirven estas pruebas.

El caso 7 se escribió primero afirmando `/login?estado=sesion-requerida`, que es lo
que produce el `<Redireccion>` del `<NotAuthorized>` en `Routes.razor`. **Falló.** Lo
que la aplicación produce de verdad es:

```
/login?returnurl=%2FHolaMundo
```

Es decir: la capa del guard que efectivamente actúa es **el middleware de
autenticación por cookies** —`options.LoginPath` con `ReturnUrlParameter`—, que corta
antes de que el `Router` llegue a evaluar su `<NotAuthorized>`.

Dos consecuencias, ninguna resuelta acá:

1. El `<NotAuthorized>` de `Routes.razor` es **camino muerto** para las páginas con
   `[Authorize]`.
2. La entrada `SesionRequerida` del catálogo —«Ingresá para ver esa superficie.»—
   **nunca se le muestra a nadie**.

Las pruebas se ajustaron a lo que la aplicación hace, no al revés: **corregir el
comportamiento es una decisión de diseño, y no la toma la prueba**. Queda anotado.

---

## 7. Lo que estos casos deliberadamente no prueban

| No se prueba | Por qué |
| --- | --- |
| El **token antifalsificación** | Es una defensa del servidor. Se prueba desde afuera del navegador, no manejándolo. |
| Los **atributos de la cookie** (`HttpOnly`, `SameSite`) | Es configuración, y se verifica leyendo el `Program.cs`. Una E2E ahí solo agregaría lentitud. |
| El **control de intentos**, el hash del secreto | No existen: la identidad es de laboratorio y lo declara en su propio `<remarks>`. |
| La **accesibilidad** del formulario | Otra clase de verificación, con otras herramientas. |

---

## 8. Cómo se corren

```bash
scripts/pruebas.sh login
REPETIR=8 scripts/pruebas.sh login
```

---

## 9. Los criterios, en una lista

1. **Afirmá el efecto, no el mecanismo.** La cookie es cómo; la superficie visible es qué.
2. **Nunca fabriques el estado que la prueba debería obtener actuando.**
3. **Derivá el andamiaje de cómo está construida la superficie**, no de la costumbre.
4. **Una propiedad negativa se prueba comparando dos desenlaces**, no mirando uno.
5. **Afirmá lo que tendría que fallar con razón**; lo reversible, dejalo suelto.
6. **Un caso, un motivo de falla.**
7. **Cada promesa escrita en el `src` es un caso esperando a ser escrito.**
