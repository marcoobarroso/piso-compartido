# Lanzar Piso Compartido en la App Store

## Cómo funciona (y por qué los cambios llegan al instante)

La app de iOS es un contenedor nativo (Capacitor) que carga la web
`https://piso-compartido.vercel.app`. Por eso:

- **Cualquier cambio de la web** (pantallas, textos, funciones, arreglos) llega a
  todos los iPhones en cuanto Vercel despliega (`git push` a `main`, ~2 min). No
  hay que volver a pasar por Apple. La app recoge la versión nueva la próxima vez
  que se abre o cuando vuelve de segundo plano tras más de 2 minutos.
- **Solo hay que volver a subir a Apple** si se cambia algo nativo: icono, nombre,
  `capacitor.config.ts`, plugins de Capacitor o código de `ios/`.

Partes nativas incluidas: notificaciones push de iOS (APNs), exportar Excel con la
hoja de compartir de iOS y una pantalla propia "Sin conexión".

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
- **Node.js 20 o superior** (https://nodejs.org) y git.
- Su cuenta de **Apple Developer** ya activa (99 €/año).

## 3. Pasos del amigo

### 3.1 Descargar el proyecto
```bash
git clone https://github.com/marcoobarroso/piso-compartido.git
cd piso-compartido
npm install
npx cap sync ios
open ios/App/App.xcodeproj
```
`npm install` es obligatorio: Xcode saca los plugins nativos de `node_modules`.

### 3.2 Firma en Xcode
Target **App** → pestaña **Signing & Capabilities**:
1. Marcar **Automatically manage signing**.
2. **Team**: su cuenta de desarrollador.
3. **Bundle Identifier**: `com.marcobarroso.pisocompartido`. Si Apple dice que no
   está disponible, poner otro (p. ej. `com.<suapellido>.pisocompartido`) y
   avisar a Marco: hay que cambiarlo también en `capacitor.config.ts` (`appId`) y
   en el secreto `APNS_BUNDLE_ID` de Supabase.
4. Debe aparecer la capability **Push Notifications** (ya viene configurada). Si no
   aparece: botón **+ Capability** → Push Notifications.

### 3.3 Clave de notificaciones (APNs)
En https://developer.apple.com/account → **Certificates, IDs & Profiles** → **Keys** → **+**:
1. Nombre: `Piso Compartido Push`, marcar **Apple Push Notifications service (APNs)**
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
- [ ] Aceptar "Activa avisos" → que otra cuenta del mismo piso añada un gasto →
      llega la notificación, y al tocarla se abre la pantalla correcta.
- [ ] Gastos → **Excel** → se abre la hoja de compartir → Guardar en Archivos.
- [ ] Invitar por WhatsApp abre WhatsApp.
- [ ] Modo avión → abrir la app → sale "Sin conexión" → quitar modo avión → Reintentar.

### 3.6 Crear la app en App Store Connect
https://appstoreconnect.apple.com → **Apps** → **+** → Nueva app:
plataforma iOS, nombre **Piso Compartido**, idioma principal **Español (España)**,
el Bundle ID de 3.2, SKU `pisocompartido`, acceso completo.

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

- **Nombre**: Piso Compartido
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
Piso Compartido reúne en un solo sitio todo lo que necesitas para convivir sin discusiones.

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
