import { createFileRoute, Link, notFound } from "@tanstack/react-router";
import { fumerAromes, type Category } from "@/lib/menu-data";

export const Route = createFileRoute("/fumer/$arome")({
  component: FumerArome,
  loader: ({ params }): Category => {
    const cat = fumerAromes.find((c) => c.slug === params.arome);
    if (!cat) throw notFound();
    return cat;
  },
  notFoundComponent: () => (
    <div className="min-h-screen flex items-center justify-center text-foreground">
      <div className="text-center">
        <p className="text-muted-foreground">Arôme introuvable</p>
        <Link to="/fumer" className="text-[color:var(--gold)] tracking-[0.3em] text-xs mt-4 inline-block">← RETOUR</Link>
      </div>
    </div>
  ),
  head: ({ loaderData }) => ({
    meta: [
      { title: `${loaderData?.label ?? "Arôme"} — Balcony` },
      { name: "description", content: loaderData?.desc ?? "Notre sélection chicha" },
    ],
  }),
});

function FumerArome() {
  const cat = Route.useLoaderData();

  return (
    <div className="min-h-screen bg-background text-foreground px-4 py-10 md:py-14">
      <header className="max-w-3xl mx-auto flex items-center justify-between">
        <Link to="/fumer" className="text-xs tracking-[0.4em] text-muted-foreground hover:text-foreground">
          ← FUMER
        </Link>
        <span className="text-xs tracking-[0.4em] text-muted-foreground">BALCONY</span>
      </header>

      <section className="text-center mt-10">
        <h1 className="text-3xl md:text-5xl italic" style={{ fontFamily: "var(--font-display)", color: "var(--gold)" }}>
          {cat.label}
        </h1>
        <p className="text-sm tracking-[0.3em] mt-3 text-muted-foreground">{cat.desc}</p>
      </section>

      <main className="max-w-2xl mx-auto mt-10 flex flex-col gap-3">
        {cat.items.map((it: Category["items"][number]) => (
          <div
            key={it.name}
            className="flex items-start justify-between gap-4 rounded-xl border border-white/10 bg-white/[0.02] p-5"
          >
            <div>
              <div className="text-base md:text-lg" style={{ fontFamily: "var(--font-display)" }}>
                {it.name}
              </div>
              {it.desc && <div className="text-xs text-muted-foreground mt-1">{it.desc}</div>}
            </div>
            <div className="text-sm md:text-base tracking-wider whitespace-nowrap" style={{ color: "var(--gold)" }}>
              {it.price}
            </div>
          </div>
        ))}
      </main>
    </div>
  );
}
