// Habilita Universal Links para que /join/[code] abra la app nativa de iOS
// en vez de Safari cuando está instalada. Debe servirse sin redirecciones y
// con Content-Type application/json (Apple lo pide así, sin extensión de
// archivo, por eso es una route handler y no un fichero estático).
export function GET() {
  return Response.json({
    applinks: {
      apps: [],
      details: [
        {
          appID: "R4U5XJ6C89.com.marcobarroso.rumis",
          paths: ["/join/*"],
        },
      ],
    },
  });
}
