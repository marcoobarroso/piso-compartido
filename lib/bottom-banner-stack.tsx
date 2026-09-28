"use client";

import { createContext, useContext, useEffect, useState } from "react";

/** Coordina los banners fijos de abajo (instalar la PWA, activar avisos)
 * para que se apilen en vez de superponerse: ambos usan `position: fixed`
 * sobre la misma franja de la pantalla, así que sin esto uno tapaba al otro
 * por completo si los dos estaban visibles a la vez. */
const PushPromptVisibleContext = createContext<{
  visible: boolean;
  setVisible: (visible: boolean) => void;
} | null>(null);

export function BottomBannerProvider({ children }: { children: React.ReactNode }) {
  const [visible, setVisible] = useState(false);
  return (
    <PushPromptVisibleContext.Provider value={{ visible, setVisible }}>
      {children}
    </PushPromptVisibleContext.Provider>
  );
}

/** Llamar desde el banner de avisos push con su propia visibilidad actual. */
export function useRegisterPushPromptVisible(isVisible: boolean) {
  const ctx = useContext(PushPromptVisibleContext);
  useEffect(() => {
    ctx?.setVisible(isVisible);
    return () => ctx?.setVisible(false);
  }, [ctx, isVisible]);
}

/** Llamar desde cualquier otro banner que deba subir un hueco cuando el de
 * avisos push también esté visible. */
export function usePushPromptVisible() {
  return useContext(PushPromptVisibleContext)?.visible ?? false;
}
