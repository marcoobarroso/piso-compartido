/** Solo permite rutas internas ("/algo"), nunca URLs externas ("//evil.com",
 * "https://...") que convertirían el login en una redirección abierta. */
export function safeNextPath(next: string | null | undefined, fallback = "/"): string {
  if (!next || !next.startsWith("/") || next.startsWith("//") || next.startsWith("/\\")) {
    return fallback;
  }
  return next;
}
