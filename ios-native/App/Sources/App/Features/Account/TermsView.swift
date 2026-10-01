import SwiftUI

/// Read-only terms-of-service screen, mirroring app/terms/page.tsx.
struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Términos de servicio")
                        .font(.title2.bold())
                        .foregroundStyle(RTheme.foreground)
                    Text("Última actualización: septiembre de 2026")
                        .font(.caption)
                        .foregroundStyle(RTheme.mutedForeground)
                }

                section(
                    "Qué es Rumis",
                    "Rumis es una aplicación gratuita para organizar un piso compartido: repartir gastos, asignar tareas domésticas por turnos y llevar una lista de la compra común. La gestiona Marco Barroso Martín como proyecto personal, sin ánimo de lucro ni publicidad."
                )

                section(
                    "Quién puede usarla",
                    "Necesitas un correo electrónico válido y, si eres menor de edad, el permiso de tu madre, padre o tutor. Cada persona solo puede pertenecer a un piso a la vez."
                )

                section(
                    "Tu cuenta y lo que compartes",
                    "Eres responsable de lo que añades a tu piso (gastos, tareas, artículos de la compra) y de a quién invitas con tu código. Tus compañeros de piso pueden ver, editar y borrar ese contenido igual que tú — Rumis es un espacio compartido, no privado, dentro de cada piso."
                )

                section(
                    "Sobre los gastos",
                    "Rumis no mueve dinero real. Los \"gastos\" y \"liquidaciones\" son anotaciones para llevar la cuenta de quién debe qué — los pagos entre compañeros los hacéis vosotros por fuera de la app (Bizum, efectivo, etc.). No nos hacemos responsables de errores en los repartos ni de pagos que no lleguen a hacerse fuera de la aplicación."
                )

                section(
                    "Uso aceptable",
                    """
                    No está permitido usar Rumis para:

                    • Compartir contenido ilegal, ofensivo o que suplante a otra persona.
                    • Intentar acceder a un piso que no es el tuyo sin invitación.
                    • Interferir con el funcionamiento del servicio o intentar sortear sus límites.

                    Podemos suspender o borrar una cuenta que incumpla esto, avisando cuando sea posible.
                    """
                )

                section(
                    "Disponibilidad del servicio",
                    "Rumis se ofrece \"tal cual\", sin garantizar que esté disponible de forma ininterrumpida. Es un proyecto pequeño y puede sufrir cortes, cambios o, en el peor caso, dejar de mantenerse — intentaremos avisar con tiempo si esto último fuera a pasar, para que puedas exportar tus datos antes."
                )

                section(
                    "Borrar tu cuenta",
                    "Puedes borrar tu cuenta cuando quieras desde Ajustes. Es inmediato e irreversible; consulta la política de privacidad para ver exactamente qué pasa con tus datos al hacerlo."
                )

                section(
                    "Cambios en estos términos",
                    "Si cambiamos algo relevante, lo reflejaremos aquí actualizando la fecha de arriba. Seguir usando la app después de un cambio implica aceptarlo."
                )

                section(
                    "Ley aplicable",
                    "Estos términos se rigen por la legislación española. Para cualquier duda, escribe a marcbarro.07@gmail.com."
                )
            }
            .padding(16)
        }
        .background(RTheme.background)
        .navigationTitle("Términos")
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
