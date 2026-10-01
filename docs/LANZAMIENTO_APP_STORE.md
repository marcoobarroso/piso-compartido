# Lanzar Rumis en la App Store

## Cómo funciona (app nativa, ya no es un contenedor web)

> **Actualizado**: la app dejó de ser un contenedor Capacitor que cargaba la
> web. Ahora es una app SwiftUI nativa (proyecto en `ios-native/`) que habla
> directo con Supabase — el código vive en este repo, pero ya no carga
> `piso-compartido.vercel.app` dentro de un WebView. Esto era precisamente
> para evitar el riesgo de rechazo por la guideline 4.2 (ver más abajo) y
> para que vaya más fluida.
>
> **Consecuencia importante**: a diferencia de antes, **un cambio en la web
> ya NO llega solo a los iPhones**. Cualquier cambio de pantallas, textos o
> funciones dentro de la app requiere compilar de nuevo y volver a subir una
> build a App Store Connect (pasos 3.6-3.9). Lo que sigue llegando al
> instante sin pasar por Apple es el propio backend (Supabase: esquema,
> RLS, funciones, Edge Function de push) y la web para navegador, que la
> app nativa no usa salvo para exportar el Excel (una llamada puntual a esa
> misma ruta).

Partes nativas: notificaciones push (APNs), exportar Excel (descarga la hoja ya
generada por la web y abre la hoja de compartir de iOS), Universal Links para que
los enlaces de invitación abran la app, y pantalla propia "Sin conexión".

---

## 1. Lo que hace Marco antes (una sola vez)

1. **SQL en Supabase** (SQL Editor): ejecutar, en este orden,
   `supabase/migrations/0014_delete_my_account.sql` y
   `supabase/migrations/0015_native_push_tokens.sql`.
2. **Edge Function `send-push`**: pegar el contenido nuevo de
   `supabase/functions/send-push/index.ts` y desplegarla (Edge Functions →
   send-push → Code → Deploy). Hasta que existan las claves de APNs (paso 3.4)
   sigue funcionando igual que ahora para la web.
3. **Dar acceso al código** al amigo: si el repo de GitHub es privado, invitarlo en
   GitHub → repo → Settings → Collaborators.

## 2. Lo que necesita el amigo

- Un Mac con la **última versión de Xcode** (Mac App Store). Apple solo acepta
  apps compiladas con el SDK actual.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) para generar el `.xcodeproj`
  (no se versiona): `brew install xcodegen`.
- Su cuenta de **Apple Developer** ya activa (99 €/año), que es la que paga y a
  cuyo nombre queda la app (ver apartado 7).

(Node.js ya no hace falta para la parte de iOS — eso era del contenedor
Capacitor antiguo, que ha desaparecido. Solo importa si también se toca la web.)

## 2bis. Daros acceso mutuo (para que Marco pueda compilar y subir él mismo)

Compilar y probar en el **simulador** no necesita nada de esto — solo hace
falta para compilar en un **iPhone físico** y para subir una build a App Store
Connect (Archive → Upload, apartado 3.7). Dos formas de hacerlo:

**Opción A — el amigo invita a Marco a su equipo (recomendado, deja a Marco
hacer todo el trabajo técnico sin depender de que el amigo esté delante del
Mac):**
1. El amigo entra en https://appstoreconnect.apple.com → **Usuarios y acceso**
   (o developer.apple.com → **Users and Access**, según dónde gestione el
   equipo).
2. **+** → invita el Apple ID de Marco.
3. Rol: **App Manager** o **Admin** (no solo "Developer") si Marco también
   tiene que crear la ficha de la app, gestionar TestFlight y enviarla a
   revisión desde App Store Connect — no solo compilarla en Xcode.
4. Marco acepta la invitación por correo, y en **Xcode → Settings → Accounts**
   añade su propio Apple ID (el suyo, no el del amigo). El equipo del amigo
   aparecerá disponible en el desplegable **Team** del apartado 3.2.
5. A partir de aquí, Marco puede compilar en su iPhone, archivar y subir la
   build él mismo — el nombre que aparece como vendedor en la App Store sigue
   siendo el del amigo (apartado 7), eso no cambia con este paso.

**Opción B — el amigo hace él mismo los pasos 3.1 a 3.9** en su propio Mac,
tal como estaba pensado originalmente (menos cómodo si Marco es quien está
haciendo los cambios de código).

Con la Opción A, el bundle id y el Team ID en `ios-native/project.yml` no
hace falta tocarlos — ya están puestos al equipo del amigo (`R4U5XJ6C89`,
el mismo que ya usaba la app actual en TestFlight/App Store).

## 3. Pasos del amigo (o de Marco, si se hizo la Opción A de arriba)

### 3.1 Descargar el proyecto
```bash
git clone https://github.com/marcoobarroso/piso-compartido.git
cd piso-compartido/ios-native
xcodegen generate
open Rumis.xcodeproj
```
`xcodegen generate` hay que volver a ejecutarlo cada vez que se añaden o borran
archivos `.swift` (el `.xcodeproj` se regenera desde `project.yml`, no se edita a
mano ni se sube a git).

### 3.2 Firma en Xcode
Target **Rumis** (no "App", ese era el nombre del target antiguo de Capacitor) →
pestaña **Signing & Capabilities**:
1. Marcar **Automatically manage signing**.
2. **Team**: su cuenta de desarrollador (sustituye al `DEVELOPMENT_TEAM` de
   `ios-native/project.yml`, que trae puesto el de Marco — hay que cambiarlo ahí
   y volver a ejecutar `xcodegen generate`, o Xcode lo pisará igualmente al
   firmar automáticamente).
3. **Bundle Identifier**: `com.marcobarroso.rumis`. Si Apple dice que no
   está disponible, poner otro (p. ej. `com.<suapellido>.rumis`) y
   avisar a Marco: hay que cambiarlo también en `PRODUCT_BUNDLE_IDENTIFIER` de
   `ios-native/project.yml` y en el secreto `APNS_BUNDLE_ID` de Supabase.
4. Debe aparecer la capability **Push Notifications** (ya viene en
   `ios-native/App/App.entitlements`). Si no aparece: botón **+ Capability** →
   Push Notifications.
5. También trae **Associated Domains** (`applinks:piso-compartido.vercel.app`),
   para que los enlaces de invitación abran la app — no hace falta tocarlo.

### 3.3 Clave de notificaciones (APNs)
En https://developer.apple.com/account → **Certificates, IDs & Profiles** → **Keys** → **+**:
1. Nombre: `Rumis Push`, marcar **Apple Push Notifications service (APNs)**
   (entorno *Sandbox & Production*) → Continue → Register.
2. **Download**: se descarga un fichero `AuthKey_XXXXXXXXXX.p8` (**solo se puede
   descargar una vez**, guardarlo bien).
3. Apuntar el **Key ID** (10 caracteres, sale en la página de la clave) y el
   **Team ID** (arriba a la derecha o en *Membership details*).
4. Pasarle a Marco por privado el `.p8`, el Key ID y el Team ID.

### 3.4 Marco guarda la clave en Supabase
Edge Functions → **Secrets** → añadir:

| Nombre | Valor |
|---|---|
| `APNS_KEY_ID` | Key ID |
| `APNS_TEAM_ID` | Team ID |
| `APNS_PRIVATE_KEY` | contenido completo del `.p8` (abrirlo con un editor de texto, incluidas las líneas BEGIN/END) |
| `APNS_BUNDLE_ID` | solo si se cambió el bundle id en 3.2 |

### 3.5 Probar en un iPhone real
Conectar el iPhone al Mac, elegirlo arriba en Xcode y pulsar ▶. Comprobar:
- [ ] Entrar con código de correo y con "Ver demo (sin registro)".
- [ ] Añadir un gasto, una tarea y un artículo de la compra.
- [ ] Aceptar el permiso de notificaciones → que otra cuenta del mismo piso añada
      un gasto o una tarea → llega la notificación, y al tocarla se abre la
      pestaña correcta (Gastos/Tareas).
- [ ] Tocar un enlace de invitación (`.../join/CÓDIGO`) desde Mensajes/Notas con la
      app instalada → debe abrir la app directamente en vez de Safari
      (Universal Links / Associated Domains).
- [ ] Gastos → **Excel** → se abre la hoja de compartir → Guardar en Archivos.
- [ ] Invitar por WhatsApp abre WhatsApp.
- [ ] Modo avión → abrir la app → sale "Sin conexión" → quitar modo avión → Reintentar.

### 3.6 Crear la app en App Store Connect
https://appstoreconnect.apple.com → **Apps** → **+** → Nueva app:
plataforma iOS, nombre **Rumis**, idioma principal **Español (España)**,
el Bundle ID de 3.2, SKU `rumis`, acceso completo.

### 3.7 Subir la build
En Xcode, destino **Any iOS Device (arm64)** → **Product → Archive** → en el
Organizer: **Distribute App → App Store Connect → Upload** (dejar las opciones por
defecto). Cada subida nueva necesita un **Build** mayor (Target App → General →
Build: 1, 2, 3…). Si se cambia la versión visible, subir también **Version** (1.0 → 1.1).

### 3.8 TestFlight (recomendado)
Tras 10–30 min la build aparece en **TestFlight**. Añadir a Marco como probador
interno (Usuarios y acceso → darle rol, o grupo de pruebas interno) y repetir la
lista de 3.5 con la app instalada desde TestFlight. Aquí las notificaciones ya van
por el APNs de producción, que es el que usará la App Store.

### 3.9 Rellenar la ficha y enviar a revisión
Con los datos del apartado 4. Seleccionar la build → **Añadir para revisión** →
**Enviar**. Suele tardar 1–3 días. Publicación: automática o manual, a elegir.

---

## 4. Datos de la ficha

- **Nombre**: Rumis
- **Subtítulo** (máx. 30): Gastos, tareas y compra
- **Categoría**: Estilo de vida (secundaria: Productividad)
- **Precio**: Gratis · **Disponibilidad**: todos los países o solo España
- **Dispositivos**: solo iPhone (el iPad no está activado)
- **URL de soporte**: https://piso-compartido.vercel.app
- **URL de privacidad**: https://piso-compartido.vercel.app/privacy
- **Copyright**: 2026 Marco Barroso Martín
- **Palabras clave** (máx. 100): `piso,compartido,gastos,tareas,compra,compañeros,deudas,dividir,convivencia,alquiler`
- **Texto promocional**: Cuentas claras y casa ordenada con tus compañeros de piso.

**Descripción**:
```
Rumis reúne en un solo sitio todo lo que necesitas para convivir sin discusiones.

GASTOS
Apunta lo que pagas y repártelo entre quienes corresponda, a partes iguales o con importes exactos. La app calcula quién debe a quién con el mínimo de pagos y te deja registrarlos. Gastos fijos que se generan solos, categorías, estadísticas y exportación a Excel.

TAREAS
Reparte las tareas de la casa con rotación automática, fechas límite y un calendario compartido. Cada uno ve lo que le toca y lo que va atrasado.

LISTA DE LA COMPRA
Una lista compartida en tiempo real, más tu propia lista personal. Todos ven lo que falta al instante.

AVISOS
Recibe una notificación cuando alguien añade un gasto, te toca una tarea o te registran un pago.

INVITA A TU PISO
Comparte un código o un enlace por WhatsApp y tus compañeros entran en segundos. Sin contraseñas: inicias sesión con un código que te llega al correo.

Prueba la demo sin registrarte desde la pantalla de inicio.
```

**Capturas** (obligatorias, iPhone 6,9"): abrir en Xcode el simulador
**iPhone Pro Max** más reciente, ejecutar la app y hacer capturas con **Cmd+S**
(salen al tamaño correcto). 4–6 capturas: Inicio, Gastos, Saldar cuentas,
Tareas/calendario, Compra, Estadísticas. Se pueden hacer con la demo.

**Clasificación por edades**: responder "No" a todo → 4+.

**Información para la revisión de la app** (App Review Information):
- Inicio de sesión necesario: **Sí** → usuario `demo1@example.com`, contraseña `DemoPiso2026!`
- Notas:
```
No hace falta crear cuenta: en la pantalla de inicio de sesión, el botón "Ver demo (sin registro)" entra en un piso de ejemplo con datos (usa la cuenta demo indicada). El inicio de sesión normal es sin contraseña, con un código de 8 dígitos que llega por correo.

Funciones nativas: notificaciones push (APNs) cuando un compañero añade un gasto o una tarea, hoja de compartir de iOS para exportar gastos a Excel, compartir invitaciones por WhatsApp y pantalla propia sin conexión. Los datos se sincronizan en tiempo real entre los compañeros de piso.

Borrado de cuenta: pestaña "Inicio" → "Borrar mi cuenta" (no disponible en la cuenta demo, que es compartida).
```

## 5. Privacidad de la app (App Privacy)

"¿Recopilas datos?" → **Sí**. Ninguno se usa para **rastreo** ni publicidad.
Todos están **vinculados a la identidad** del usuario salvo los de diagnóstico.

| Categoría → dato | Uso | Vinculado |
|---|---|---|
| Información de contacto → Correo electrónico | Funcionalidad de la app | Sí |
| Información de contacto → Nombre | Funcionalidad de la app | Sí |
| Contenido del usuario → Otro contenido del usuario (gastos, tareas, compra) | Funcionalidad de la app | Sí |
| Identificadores → ID de usuario | Funcionalidad de la app | Sí |
| Diagnóstico → Datos de fallos y de rendimiento | Funcionalidad de la app | No |
| Datos de uso → Interacción con el producto | Analíticas | No |

No se recopilan: ubicación, contactos, fotos, salud, datos financieros (los gastos
son anotaciones entre compañeros; la app no mueve dinero), historial de búsqueda
ni de navegación.

**Cifrado**: ya está declarado en la app que solo usa cifrado estándar (HTTPS), así
que App Store Connect no pedirá documentación de exportación.

---

## 6. Si Apple la rechaza

- **Guideline 4.2 (Minimum Functionality / "es solo una web")**: responder en el
  Centro de resoluciones explicando las funciones nativas (push, hoja de compartir,
  pantalla sin conexión) y el uso colaborativo en tiempo real. Pegar las notas de
  revisión de arriba.
- **Guideline 2.1 (no han podido entrar)**: comprobar que el botón "Ver demo" funciona
  en https://piso-compartido.vercel.app/login y que la cuenta demo existe (si se ha
  estropeado, volver a ejecutar `supabase/migrations/0012_demo_seed.sql`).
- **Guideline 5.1.1 (datos/cuenta)**: el borrado de cuenta está en la pestaña Inicio.

## 7. Quién figura como vendedor

La app se publica a nombre del titular de la cuenta de Apple Developer (el amigo):
aparecerá su nombre como vendedor en la App Store. Si más adelante Marco tiene su
propia cuenta, se puede transferir desde App Store Connect (App → Información de la
app → Transferir app) sin perder usuarios ni valoraciones.
