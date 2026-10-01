import SwiftUI

/// Read-only privacy policy screen, condensed from app/privacy/page.tsx.
/// Static content — not a legal document requiring verbatim reproduction.
struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Política de privacidad")
                        .font(.title2.bold())
                        .foregroundStyle(RTheme.foreground)
                    Text("Última actualización: septiembre de 2026")
                        .font(.caption)
                        .foregroundStyle(RTheme.mutedForeground)
                }

                section(
                    "Quién es el responsable",
                    "Rumis está desarrollada y gestionada por Marco Barroso Martín. Para cualquier consulta sobre esta política o sobre tus datos, escribe a marcbarro.07@gmail.com."
                )

                section(
                    "Qué datos recopilamos",
                    """
                    • Tu correo electrónico, para identificarte (inicio de sesión sin contraseña).
                    • El nombre que elijas mostrar dentro de tu piso.
                    • Los datos que introduces al usar la app: gastos, reparto entre compañeros, tareas domésticas, lista de la compra y mensajes de invitación.
                    • Si activas los avisos, un identificador técnico de tu dispositivo para poder enviarte notificaciones (no incluye tu ubicación ni el contenido de otras apps).
                    • Datos técnicos básicos de uso y errores, para poder arreglar fallos y entender qué partes de la app se usan más.
                    """
                )

                section(
                    "Para qué los usamos",
                    "Solo usamos tus datos para que la app funcione: gestionar tu piso compartido, calcular y mostrar saldos entre compañeros, asignar tareas, mantener la lista de la compra al día, enviarte el código de acceso y, si lo activas, avisos push. No usamos tus datos con fines publicitarios ni los vendemos a terceros."
                )

                section(
                    "Con quién los compartimos",
                    """
                    No compartimos tus datos con nadie fuera de tu piso salvo con los proveedores técnicos que hacen posible la app, como encargados del tratamiento:

                    • Supabase — base de datos, autenticación y almacenamiento.
                    • Vercel — alojamiento de la aplicación y estadísticas de uso anónimas.
                    • Brevo — envío del correo con el código de acceso.
                    • Sentry — registro de errores técnicos para poder solucionarlos.
                    • Apple (APNs) — entrega de notificaciones push en iOS.
                    """
                )

                section(
                    "Cuánto tiempo los guardamos",
                    "Guardamos tus datos mientras tengas una cuenta activa. Puedes borrar tu cuenta tú mismo en cualquier momento desde Ajustes (\"Borrar mi cuenta\"): se elimina tu correo y tus credenciales, sales del piso y tu nombre pasa a mostrarse como \"Usuario eliminado\" en el historial de gastos de tus compañeros, que se conserva para que sus cuentas sigan cuadrando."
                )

                section(
                    "Tus derechos",
                    "Puedes pedirnos en cualquier momento acceder a tus datos, corregirlos, exportarlos o borrarlos por completo, escribiendo a marcbarro.07@gmail.com. Responderemos lo antes posible."
                )

                section(
                    "Cambios en esta política",
                    "Si cambiamos algo importante de cómo tratamos tus datos, lo reflejaremos aquí actualizando la fecha de arriba."
                )
            }
            .padding(16)
        }
        .background(RTheme.background)
        .navigationTitle("Privacidad")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(RTheme.cardForeground)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(RTheme.mutedForeground)
        }
    }
}
