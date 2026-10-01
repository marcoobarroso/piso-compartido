import { BackLink } from "../privacy/back-link";

export const metadata = {
  title: "Términos de servicio · Rumis",
};

export default function TermsPage() {
  return (
    <div className="mx-auto flex w-full max-w-2xl flex-1 flex-col gap-6 p-4 py-8">
      <div>
        <BackLink />
      </div>

      <div className="flex flex-col gap-1">
        <h1 className="font-heading text-2xl font-semibold">Términos de servicio</h1>
        <p className="text-sm text-muted-foreground">Última actualización: septiembre de 2026</p>
      </div>

      <Section title="Qué es Rumis">
        <p>
          Rumis es una aplicación gratuita para organizar un piso compartido: repartir gastos,
          asignar tareas domésticas por turnos y llevar una lista de la compra común. La gestiona{" "}
          <strong>Marco Barroso Martín</strong> como proyecto personal, sin ánimo de lucro ni
          publicidad.
        </p>
      </Section>

      <Section title="Quién puede usarla">
        <p>
          Necesitas un correo electrónico válido y, si eres menor de edad, el permiso de tu
          madre, padre o tutor. Cada persona solo puede pertenecer a un piso a la vez.
        </p>
      </Section>

      <Section title="Tu cuenta y lo que compartes">
        <p>
          Eres responsable de lo que añades a tu piso (gastos, tareas, artículos de la compra) y
          de a quién invitas con tu código. Tus compañeros de piso pueden ver, editar y borrar ese
          contenido igual que tú — Rumis es un espacio compartido, no privado, dentro de cada
          piso.
        </p>
      </Section>

      <Section title="Sobre los gastos">
        <p>
          <strong>Rumis no mueve dinero real.</strong> Los &quot;gastos&quot; y
          &quot;liquidaciones&quot; son anotaciones para llevar la cuenta de quién debe qué —
          los pagos entre compañeros los hacéis vosotros por fuera de la app (Bizum, efectivo,
          etc.). No nos hacemos responsables de errores en los repartos ni de pagos que no
          lleguen a hacerse fuera de la aplicación.
        </p>
      </Section>

      <Section title="Uso aceptable">
        <p>No está permitido usar Rumis para:</p>
        <ul className="list-disc pl-5">
          <li>Compartir contenido ilegal, ofensivo o que suplante a otra persona.</li>
          <li>Intentar acceder a un piso que no es el tuyo sin invitación.</li>
          <li>Interferir con el funcionamiento del servicio o intentar sortear sus límites.</li>
        </ul>
        <p>
          Podemos suspender o borrar una cuenta que incumpla esto, avisando cuando sea posible.
        </p>
      </Section>

      <Section title="Disponibilidad del servicio">
        <p>
          Rumis se ofrece &quot;tal cual&quot;, sin garantizar que esté disponible de forma
          ininterrumpida. Es un proyecto pequeño y puede sufrir cortes, cambios o, en el peor
          caso, dejar de mantenerse — intentaremos avisar con tiempo si esto último fuera a
          pasar, para que puedas exportar tus datos antes.
        </p>
      </Section>

      <Section title="Borrar tu cuenta">
        <p>
          Puedes borrar tu cuenta cuando quieras desde la pestaña Inicio. Es inmediato e
          irreversible; consulta la{" "}
          <a href="/privacy" className="text-primary hover:underline">
            política de privacidad
          </a>{" "}
          para ver exactamente qué pasa con tus datos al hacerlo.
        </p>
      </Section>

      <Section title="Cambios en estos términos">
        <p>
          Si cambiamos algo relevante, lo reflejaremos aquí actualizando la fecha de arriba. Seguir
          usando la app después de un cambio implica aceptarlo.
        </p>
      </Section>

      <Section title="Ley aplicable">
        <p>
          Estos términos se rigen por la legislación española. Para cualquier duda, escribe a{" "}
          <a href="mailto:marcbarro.07@gmail.com" className="text-primary hover:underline">
            marcbarro.07@gmail.com
          </a>
          .
        </p>
      </Section>
    </div>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="flex flex-col gap-2">
      <h2 className="font-heading text-base font-semibold">{title}</h2>
      <div className="flex flex-col gap-2 text-sm leading-relaxed text-muted-foreground">
        {children}
      </div>
    </div>
  );
}
