import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { Analytics } from "@vercel/analytics/next";
import { Toaster } from "@/components/ui/sonner";
import { InstallPrompt } from "@/components/install-prompt";
import { RegisterServiceWorker } from "@/components/register-service-worker";
import { ThemeProvider } from "@/components/theme-provider";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  metadataBase: new URL("https://piso-compartido.vercel.app"),
  title: "Piso Compartido",
  description: "Gastos, tareas y compra compartidos entre compañeros de piso",
  openGraph: {
    title: "Piso Compartido",
    description: "Gastos, tareas y compra compartidos entre compañeros de piso",
    url: "https://piso-compartido.vercel.app",
    siteName: "Piso Compartido",
    locale: "es_ES",
    type: "website",
  },
};

export const viewport = {
  themeColor: "#0a0a0a",
  viewportFit: "cover" as const,
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="es"
      suppressHydrationWarning
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">
        <ThemeProvider attribute="class" defaultTheme="dark" enableSystem={false}>
          {children}
          <Toaster />
          <InstallPrompt />
          <RegisterServiceWorker />
          <Analytics />
        </ThemeProvider>
      </body>
    </html>
  );
}
