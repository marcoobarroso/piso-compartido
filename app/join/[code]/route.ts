import { NextResponse, type NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ code: string }> }
) {
  const { code } = await params;
  const supabase = await createClient();

  const { error } = await supabase.rpc("join_household", {
    _invite_code: code,
  });

  const url = request.nextUrl.clone();
  url.search = "";

  if (!error) {
    url.pathname = "/household";
  } else if (/ya perteneces/i.test(error.message)) {
    // Ya está en otro piso: /onboarding lo devolvería a /household sin decir
    // nada, así que se le explica por qué no se ha podido unir.
    url.pathname = "/household";
    url.searchParams.set("joinError", "other");
  } else {
    url.pathname = "/onboarding";
    url.searchParams.set("error", "invite");
  }

  return NextResponse.redirect(url);
}
