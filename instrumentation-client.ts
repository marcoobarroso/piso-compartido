import * as Sentry from "@sentry/nextjs";

// Sin NEXT_PUBLIC_SENTRY_DSN configurado, el SDK simplemente no envía nada
// (no rompe nada en local ni antes de crear la cuenta de Sentry).
Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 0.2,
  replaysSessionSampleRate: 0,
  replaysOnErrorSampleRate: 0,
  // El navegador aborta una View Transition si la pestaña pasa a segundo
  // plano a mitad de la navegación (volver de otra app, cambiar de pestaña):
  // es el comportamiento normal del estándar, no un fallo real, pero React
  // lo reporta como error recuperable.
  ignoreErrors: [/Transition was aborted because of invalid state/],
});

export const onRouterTransitionStart = Sentry.captureRouterTransitionStart;
