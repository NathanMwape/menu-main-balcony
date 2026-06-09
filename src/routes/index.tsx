import { createFileRoute, Link } from "@tanstack/react-router";
import boire from "@/assets/boire.jpg";
import fumer from "@/assets/fumer.jpg";
import evenements from "@/assets/evenements.jpg";
import paiements from "@/assets/paiements.jpg";
import logo from "@/assets/logo.png";

const BRAND_NAME = "BALCONY";
const BRAND_TAGLINE = "─ LOUNGE BAR ─";

export const Route = createFileRoute("/")({
  component: Index,
  head: () => ({
    meta: [
      { title: "BALCONY LOUNGE — Menu" },
      { name: "description", content: "Par où voulez-vous commencer ? Découvrez l'expérience Cairo Lounge." },
    ],
  }),
});

const items = [
  { label: "BOIRE", img: boire, to: "/boire" },
  { label: "FUMER", img: fumer, to: "/fumer" },
  { label: "ÉVÉNEMENTS", img: evenements, to: "/evenements" },
  { label: "PAIEMENTS", img: paiements, to: "/paiements" },
];

function Index() {
  return (
    <div className="min-h-screen bg-background text-foreground px-4 py-10 md:py-14">
      <header className="flex flex-col items-center">
        <img src={logo} alt={BRAND_NAME} className="h-24 md:h-32 w-auto" />
        <div className="text-[10px] tracking-[0.5em] mt-2 text-muted-foreground">
          {BRAND_TAGLINE}
        </div>
      </header>

      <section className="text-center mt-12 md:mt-16">
        <h1
          className="text-2xl md:text-3xl italic"
          style={{ fontFamily: "var(--font-display)" }}
        >
          Par où voulez-vous
        </h1>
        <p
          className="text-2xl md:text-3xl italic mt-1"
          style={{ fontFamily: "var(--font-display)", color: "var(--gold)" }}
        >
          commencer ?
        </p>
      </section>

      <main className="mt-12 max-w-xl mx-auto flex flex-col gap-5">
        {items.map((it) => (
          <Link
            key={it.label}
            to={it.to}
            className="group relative block h-32 md:h-36 rounded-2xl overflow-hidden border border-white/5 shadow-[0_10px_40px_-15px_rgba(0,0,0,0.8)] transition-transform hover:scale-[1.02]"
          >
            <img
              src={it.img}
              alt={it.label}
              loading="lazy"
              width={1280}
              height={512}
              className="absolute inset-0 w-full h-full object-cover opacity-70 group-hover:opacity-90 transition-opacity"
            />
            <div className="absolute inset-0 bg-gradient-to-r from-black/85 via-black/40 to-black/30" />
            <div className="relative z-10 flex h-full items-end p-5">
              <span
                className="text-xl md:text-2xl tracking-[0.25em] text-white"
                style={{ fontFamily: "var(--font-display)" }}
              >
                {it.label}
              </span>
            </div>
          </Link>
        ))}
      </main>

      <footer className="text-center mt-16 text-[10px] tracking-[0.3em] text-muted-foreground uppercase">
        NI BA TOTO!
      </footer>
    </div>
  );
}
