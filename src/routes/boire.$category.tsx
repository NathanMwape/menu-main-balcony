import { createFileRoute, Link, notFound } from "@tanstack/react-router";
import { boireCategories, type Category } from "@/lib/menu-data";

export const Route = createFileRoute("/boire/$category")({
  component: BoireCategory,
  loader: ({ params }): Category => {
    const cat = boireCategories.find((c) => c.slug === params.category);
    if (!cat) throw notFound();
    return cat;
  },
  notFoundComponent: () => (
    <div className="min-h-screen flex items-center justify-center text-foreground">
      <div className="text-center">
        <p className="text-muted-foreground">Catégorie introuvable</p>
        <Link to="/boire" className="text-[color:var(--gold)] tracking-[0.3em] text-xs mt-4 inline-block">← RETOUR</Link>
      </div>
    </div>
  ),
  head: ({ loaderData }) => ({
    meta: [
      { title: `${loaderData?.label ?? "Catégorie"} — Balcony lounge` },
      { name: "description", content: loaderData?.desc ?? "Notre sélection" },
    ],
  }),
});

function BoireCategory() {
  const cat = Route.useLoaderData();

  return (
    <div className="min-h-screen bg-background text-foreground px-4 py-10 md:py-14">
      <header className="max-w-6xl mx-auto flex items-center justify-between">
        <Link
          to="/boire"
          className="group inline-flex items-center gap-2 text-xs tracking-[0.4em] text-muted-foreground hover:text-[color:var(--gold)] transition-colors border border-white/10 hover:border-[color:var(--gold)] rounded-full px-4 py-2"
        >
          <span className="transition-transform group-hover:-translate-x-0.5">←</span>
          BOIRE
        </Link>
        <span className="text-xs tracking-[0.4em] text-muted-foreground">BALCONY LOUNGE</span>
      </header>

      <section className="text-center mt-14 md:mt-20">
        <h1
          className="neon text-5xl md:text-7xl lg:text-8xl tracking-[0.15em] uppercase"
          style={{ fontFamily: "var(--font-display)", fontWeight: 600 }}
        >
          {cat.label}
        </h1>
        <div className="flex items-center justify-center gap-4 mt-6 text-muted-foreground">
          <span className="h-px w-10 bg-[color:var(--gold)]/40" />
          <p className="text-xs md:text-sm tracking-[0.4em] uppercase">{cat.desc}</p>
          <span className="h-px w-10 bg-[color:var(--gold)]/40" />
        </div>
      </section>

      <main className="max-w-6xl mx-auto mt-12 grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-5">
        {cat.items.map((it: Category["items"][number]) => (
          <div
            key={it.name}
            className="group flex flex-col items-center text-center rounded-2xl border border-white/10 bg-white/[0.02] p-5 hover:border-[color:var(--gold)] transition-colors"
          >
            <div className="aspect-[3/4] w-full rounded-xl overflow-hidden mb-4 flex items-center justify-center bg-gradient-to-b from-white/[0.04] to-transparent border border-white/5">
              {it.image ? (
                <img src={it.image} alt={it.name} className="h-full w-full object-contain" loading="lazy" />
              ) : (
                <span
                  className="text-5xl opacity-40 group-hover:opacity-70 transition-opacity"
                  style={{ color: "var(--gold)" }}
                >
                  🍾
                </span>
              )}
            </div>
            <h3
              className="text-base md:text-lg italic"
              style={{
                fontFamily: "var(--font-display)",
                color: "var(--gold)",
                textShadow: "0 0 12px color-mix(in oklab, var(--gold) 40%, transparent)",
              }}
            >
              {it.name}
            </h3>
            {it.desc && <p className="text-xs text-muted-foreground mt-1">{it.desc}</p>}
            <p className="text-sm tracking-[0.2em] mt-2 text-foreground/80">{it.price}</p>
          </div>
        ))}
      </main>
    </div>
  );
}
