import { Suspense } from "react";
import Link from "next/link";
import { LoginForm } from "./login-form";
import { DemoLoginButton } from "./demo-login-button";
import { DeletedNotice } from "./deleted-notice";

export default function LoginPage() {
  return (
    <div className="flex flex-1 flex-col items-center justify-center gap-4 p-4">
      <Suspense fallback={null}>
        <DeletedNotice />
      </Suspense>
      <Suspense fallback={null}>
        <LoginForm />
      </Suspense>
      <Suspense fallback={null}>
        <DemoLoginButton />
      </Suspense>
      <div className="flex items-center gap-3 text-xs text-muted-foreground">
        <Link href="/privacy" className="hover:underline">
          Política de privacidad
        </Link>
        <span aria-hidden>·</span>
        <Link href="/terms" className="hover:underline">
          Términos de servicio
        </Link>
      </div>
    </div>
  );
}
