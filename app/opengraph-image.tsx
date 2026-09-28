import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { ImageResponse } from "next/og";

export const alt = "Rumis";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default async function Image() {
  const iconFile = await readFile(join(process.cwd(), "public/icon-512.png"));
  const iconSrc = `data:image/png;base64,${iconFile.toString("base64")}`;

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          backgroundColor: "#0a0a0a",
          backgroundImage:
            "radial-gradient(circle at 12% -10%, rgba(232,115,74,0.32) 0%, transparent 55%), radial-gradient(circle at 100% 10%, rgba(232,115,74,0.16) 0%, transparent 50%)",
          padding: "90px",
        }}
      >
        <img
          src={iconSrc}
          alt=""
          width={100}
          height={100}
          style={{ borderRadius: 26, marginBottom: 44 }}
        />
        <div
          style={{
            display: "flex",
            fontSize: 76,
            fontWeight: 700,
            color: "#fafafa",
            letterSpacing: "-0.02em",
          }}
        >
          Rumis
        </div>
        <div
          style={{
            display: "flex",
            fontSize: 32,
            color: "#a3a3a3",
            marginTop: 22,
            maxWidth: 800,
          }}
        >
          Gastos, tareas y compra compartidos entre compañeros de piso
        </div>
        <div style={{ display: "flex", gap: 16, marginTop: 50 }}>
          {["Reparto de gastos", "Tareas rotativas", "Notificaciones push"].map((tag) => (
            <div
              key={tag}
              style={{
                display: "flex",
                fontSize: 22,
                color: "#e8734a",
                border: "2px solid rgba(232,115,74,0.45)",
                borderRadius: 999,
                padding: "10px 26px",
              }}
            >
              {tag}
            </div>
          ))}
        </div>
      </div>
    ),
    { ...size }
  );
}
