# Lanzar Piso Compartido en la App Store

La app es una web (Next.js en Vercel) envuelta en un contenedor nativo con Capacitor.
El contenedor carga `https://piso-compartido.vercel.app`, así que **cualquier cambio de
la web llega a la app sin volver a subir nada a Apple**. Solo hay que resubir a Apple si
cambia algo nativo (icono, `capacitor.config.ts`, plugins).

## Parte A: lo que hace el amigo (Mac + cuenta de pago)

Requisitos: Mac con Xcode (última versión estable) y Node.js 20+.

1. **Traerse el código**
   ```bash
   git clone <URL-del-repo> piso-compartido
   cd piso-compartido
   npm install
   npx cap sync ios
   ```
2. **Abrir el proyecto**: `open ios/App/App.xcodeproj`
3. **Firma** (Xcode → target *App* → *Signing & Capabilities*):
   - Marcar *Automatically manage signing*.
   - *Team*: su cuenta de Apple Developer.
   - *Bundle Identifier*: `com.marcobarroso.pisocompartido` (si Apple dice que ya está
     cogido, cambiarlo por otro, p. ej. `com.<apellido>.pisocompartido`, **y cambiar el mismo
     valor en `capacitor.config.ts` → `appId`**, y volver a ejecutar `npx cap sync ios`).
4. **Probar** en un iPhone real o simulador (▶). Comprobar: login por código, "Ver demo",
   añadir un gasto, cerrar sesión.
5. **Crear la ficha en App Store Connect** (https://appstoreconnect.apple.com → Apps → +):
   - Plataforma iOS, nombre *Piso Compartido*, idioma principal Español (España),
     Bundle ID el de arriba, SKU: `pisocompartido`.
6. **Subir el binario**: en Xcode elegir destino *Any iOS Device (arm64)* →
   *Product → Archive* → *Distribute App → App Store Connect → Upload*.
7. **TestFlight (recomendado antes de enviar a revisión)**: tras procesarse la build
   (10–30 min) aparece en App Store Connect → TestFlight. Añadir a Marco como probador
   interno y comprobar que todo funciona instalada desde TestFlight.
8. **Completar la ficha** (ver Parte B) → seleccionar la build → *Enviar a revisión*.
   La revisión suele tardar 1–3 días.

## Parte B: datos de la ficha en App Store Connect

**Nombre**: Piso Compartido
**Subtítulo** (30 car.): Gastos, tareas y compra
**Categoría**: Estilo de vida (secundaria: Finanzas o Productividad)
**Precio**: Gratis · **Edad**: 4+ · **Dispositivos**: solo iPhone
**URL de soporte**: https://piso-compartido.vercel.app (o mailto si lo piden)
**URL de privacidad**: https://piso-compartido.vercel.app/privacy
**Palabras clave** (100 car.): piso,compartido,gastos,tareas,compra,compañeros,deudas,dividir,convivencia
**Texto promocional**: Cuentas claras y casa ordenada con tus compañeros de piso.

**Descripción**:
> Piso Compartido reúne en un solo sitio todo lo que necesitas para convivir sin
> discusiones.
>
> GASTOS
> Apunta lo que pagas y repártelo entre quienes corresponda, a partes iguales o con
> importes exactos. La app calcula quién debe a quién con el mínimo de pagos y te deja
> registrar los pagos. Gastos fijos que se generan solos, categorías, estadísticas y
> exportación a Excel.
>
> TAREAS
> Reparte las tareas de la casa con rotación automática, fechas límite y un calendario
> compartido. Cada uno ve lo que le toca y lo que va atrasado.
>
> LISTA DE LA COMPRA
> Una lista compartida en tiempo real, más tu propia lista personal. Todos ven lo que
> falta al instante.
>
> INVITA A TU PISO
> Comparte un código o un enlace por WhatsApp y tus compañeros entran en segundos. Sin
> contraseñas: inicias sesión con un código que te llega al correo.
>
> Prueba la demo sin registrarte desde la pantalla de inicio.

**Notas para el revisor de Apple** (campo *App Review Information*):
> No hace falta cuenta para revisar la app: en la pantalla de inicio de sesión hay un
> botón "Ver demo (sin registro)" que entra en un piso de ejemplo con datos. Si prefieres
> una cuenta: correo demo1@example.com, contraseña DemoPiso2026! (se usa mediante ese mismo
> botón). El inicio de sesión normal usa un código de 8 dígitos enviado por correo, por
> eso proporcionamos el acceso demo. La app permite borrar la cuenta desde la pestaña
> "Piso" → "Borrar mi cuenta". Es una herramienta de gestión colaborativa con
> funcionalidades como avisos en tiempo real, compartir por WhatsApp y exportar a Excel,
> no un simple sitio web empaquetado.

**Capturas**: obligatorias para iPhone 6.9" (1320×2868) o 6.7" (1290×2796). Hacer 4–6 con
el simulador o un iPhone: Inicio, Gastos, Saldar cuentas, Tareas/calendario, Compra, Piso.

## Cuestionario "Privacidad de la app" (App Privacy)

Datos **vinculados al usuario**, usados solo para *funcionalidad de la app* y **sin
seguimiento (tracking)**:

| Tipo | Dato | Motivo |
|---|---|---|
| Información de contacto | Dirección de correo | Funcionalidad, autenticación |
| Información de contacto | Nombre (el que elige el usuario) | Funcionalidad |
| Contenido del usuario | Otros contenidos (gastos, tareas, compra) | Funcionalidad |
| Datos de uso / diagnóstico | Datos de rendimiento y fallos (Sentry) | Análisis / funcionalidad |
| Identificadores | ID de usuario | Funcionalidad |

No se recopilan: ubicación, contactos, fotos, datos financieros reales (los gastos son
anotaciones entre compañeros, no hay pagos), historial de navegación, publicidad.
**Cifrado / exportación**: la app solo usa HTTPS estándar → ya marcado como exento
(`ITSAppUsesNonExemptEncryption = false`).

## Riesgos conocidos y qué hacer si Apple rechaza

- **Guideline 4.2 (funcionalidad mínima / "solo una web")**: el riesgo más probable. Si
  llega, responder explicando en las notas: sincronización en tiempo real, sesión
  persistente, acciones específicas de piso, y que se están añadiendo notificaciones
  push nativas. Si insisten, la solución es la Fase 2 de abajo.
- **Fase 2 (opcional, tras publicar)**: notificaciones push nativas (APNs con el plugin
  `@capacitor/push-notifications`). Necesita una clave APNs (.p8) de la cuenta de Apple
  Developer y adaptar la función `send-push`. Hoy, dentro de la app nativa, los avisos
  funcionan **solo dentro de la app** (campana), no como notificación del sistema.
- **Cuenta del vendedor**: la app aparecerá publicada a nombre de quien tenga la cuenta
  de Apple Developer. Se puede transferir a otra cuenta después desde App Store Connect
  (Apps → Transferencia de app).
