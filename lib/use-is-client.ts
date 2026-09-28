import { useSyncExternalStore } from "react";

function subscribe() {
  return () => {};
}

/**
 * True once hydrated on the client, false during SSR — without the extra
 * render+effect roundtrip a `useState` + `useEffect(() => setMounted(true))`
 * flag would need.
 */
export function useIsClient(): boolean {
  return useSyncExternalStore(
    subscribe,
    () => true,
    () => false
  );
}
