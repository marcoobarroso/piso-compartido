import { BackLink } from "./back-link";

export const metadata = {
  title: "Política de privacidad · Piso Compartido",
};

export default function PrivacyPage() {
  return (
    <div className="mx-auto flex w-full max-w-2xl flex-1 flex-col gap-6 p-4 py-8">
      <div>
        <BackLink />
      </div>

      <div className="flex flex-col gap-1">
        <h1 className="font-heading text-2xl font-semibold">Política de privacidad</h1>
        <p className="text-sm text-muted-foreground">Última actualización: septiembre de 2026</p>
      </div>

      <Section title="Quién es el responsable">
        <p>
          Piso Compartido es una aplicación desarrollada y gestionada por{" "}
          <strong>Marco Barroso Martín</strong>. Para cualquier consulta sobre esta política o sobre tus
          datos, puedes escribir a{" "}
          <a href="mailto:marcbarro.07@gmail.com" className="text-primary hover:underline">
            marcbarro.07@gmail.com
          </a>
          .
        </p>
      </Section>

      <Section title="Qué datos recopilamos">
        <p>Al usar la app tratamos los siguientes datos:</p>
        <ul className="list-disc pl-5">
          <li>Tu correo electrónico, para poder identificarte (inicio de sesión sin contraseña).</li>
          <li>El nombre que elijas mostrar dentro de tu piso.</li>
          <li>
            Los datos que introduces al usar la app: gastos, reparto entre compañeros, tareas
            domésticas, lista de la compra y mensajes de invitación.
          </li>
          <li>
            Si activas los avisos, un identificador técnico de tu dispositivo para poder enviarte
            notificaciones (no incluye tu ubicación ni el contenido de otras apps).
          </li>
          <li>
            Datos técnicos básicos de uso (páginas visitadas, errores producidos) para poder
            arreglar fallos y entender qué partes de la app se usan más.
          </li>
        </ul>
      </Section>

      <Section title="Para qué los usamos">
        <p>
          Solo usamos tus datos para que la aplicación funcione: gestionar tu piso compartido,
          calcular y mostrar saldos entre compañeros, asignar tareas, mantener la lista de la
          compra al día, enviarte el código de acceso y, si lo activas, avisos push. No usamos tus
          datos con fines publicitarios ni los vendemos a terceros.
        </p>
      </Section>

      <Section title="Con quién los compartimos">
        <p>
          No compartimos tus datos con nadie fuera de tu piso salvo con los proveedores técnicos
          que hacen posible la app, que actúan como encargados del tratamiento:
        </p>
        <ul className="list-disc pl-5">
          <li>
            <strong>Supabase</strong> — base de datos, autenticación y almacenamiento.
          </li>
          <li>
            <strong>Vercel</strong> — alojamiento de la aplicación y estadísticas de uso anónimas
            (Vercel Analytics, que no usa cookies de rastreo).
          </li>
          <li>
            <strong>Brevo</strong> — envío del correo con el código de acceso.
          </li>
          <li>
            <strong>Sentry</strong> — registro de errores técnicos para poder solucionarlos.
          </li>
        </ul>
      </Section>

      <Section title="Cuánto tiempo los guardamos">
        <p>
          Guardamos tus datos mientras tengas una cuenta activa. Puedes borrar tu cuenta tú
          mismo en cualquier momento desde la pestaña Inicio (&quot;Borrar mi cuenta&quot;): se elimina
          tu correo y tus credenciales, sales del piso y tu nombre pasa a mostrarse como &quot;Usuario
          eliminado&quot; en el historial de gastos de tus compañeros, que se conserva para que sus
          cuentas sigan cuadrando.
        </p>
      </Section>

      <Section title="Tus derechos">
        <p>
          Puedes pedirnos en cualquier momento acceder a tus datos, corregirlos, exportarlos o
          borrarlos por completo, escribiendo a{" "}
          <a href="mailto:marcbarro.07@gmail.com" className="text-primary hover:underline">
            marcbarro.07@gmail.com
          </a>
          . Responderemos lo antes posible.
        </p>
      </Section>

      <Section title="Cookies">
        <p>
          Usamos únicamente una cookie técnica necesaria para mantener tu sesión iniciada. No
          usamos cookies de publicidad ni de rastreo entre webs.
        </p>
      </Section>

      <Section title="Cambios en esta política">
        <p>
          Si cambiamos algo importante de cómo tratamos tus datos, lo reflejaremos aquí actualizando
          la fecha de arriba.
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
