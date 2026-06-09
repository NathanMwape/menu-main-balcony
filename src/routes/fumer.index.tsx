import { createFileRoute, Link } from "@tanstack/react-router";
import { fumerAromes } from "@/lib/menu-data";

export const Route = createFileRoute("/fumer/")({
  component: Fumer,
  head: () => ({
    meta: [
      { title: "Fumer — balcony lounge" },
      { name: "description", content: "Nos arômes de chicha : double pomme, menthe, fruits rouges et plus." },
    ],
  }),
});

function Fumer() {
  return (
    <div className="min-h-screen bg-background text-foreground px-4 py-10 md:py-14">
      <header className="max-w-3xl mx-auto flex items-center justify-between">
        <Link to="/" className="text-xs tracking-[0.4em] text-muted-foreground hover:text-foreground">
          ← RETOUR
        </Link>
        <span className="text-xs tracking-[0.4em] text-muted-foreground">BALCONY LOUNGE</span>
      </header>

      <section className="text-center mt-10">
        <h1 className="text-3xl md:text-5xl italic" style={{ fontFamily: "var(--font-display)", color: "var(--gold)" }}>
          Fumer
        </h1>
        <p className="text-sm tracking-[0.3em] mt-3 text-muted-foreground">CHOISISSEZ VOTRE ARÔME</p>
      </section>

      <main className="max-w-3xl mx-auto mt-10 grid grid-cols-2 md:grid-cols-3 gap-4">
        {fumerAromes.map((c) => (
          <Link
            key={c.slug}
            to="/fumer/$arome"
            params={{ arome: c.slug }}
            className="group rounded-2xl border border-white/10 bg-white/[0.02] p-6 text-left hover:border-[color:var(--gold)] transition-colors block"
          >
            <div className="text-lg md:text-xl tracking-[0.2em]" style={{ fontFamily: "var(--font-display)" }}>
              {c.label}
            </div>
            <div className="text-xs text-muted-foreground mt-2">{c.desc}</div>
            <div className="text-[10px] tracking-[0.3em] mt-4 text-[color:var(--gold)] opacity-0 group-hover:opacity-100 transition-opacity">
              VOIR →
            </div>
          </Link>
        ))}
      </main>
    </div>
  );
}
