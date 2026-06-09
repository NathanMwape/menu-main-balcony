import { createFileRoute, Link } from "@tanstack/react-router";
import { useState } from "react";

export const Route = createFileRoute("/paiements")({
  component: Paiements,
  head: () => ({
    meta: [
      { title: "Paiements — Nixon" },
      { name: "description", content: "Méthodes de paiement : Airtel Money, Orange Money, M-Pesa et virement bancaire." },
    ],
  }),
});

// 👉 Personnalisez ici vos numéros et coordonnées bancaires
const methods = [
  { label: "AIRTEL MONEY", account: "+243 995 544 390", holder: "Balcony lounge" },
  { label: "ORANGE MONEY", account: "+243 891 701 900", holder: "balcony lounge" },
  { label: "M-PESA", account: "+243 814 044 112", holder: "balcony lounge" },
  { label: "BANQUE", account: "00000-00000000-00", holder: "Balcony lounge", bank: "Equity BCDC" },
];

function Paiements() {
  const [copied, setCopied] = useState<string | null>(null);

  const copy = (txt: string, key: string) => {
    navigator.clipboard.writeText(txt);
    setCopied(key);
    setTimeout(() => setCopied(null), 1500);
  };

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
          Paiements
        </h1>
        <p className="text-sm tracking-[0.3em] mt-3 text-muted-foreground">CHOISISSEZ UNE MÉTHODE</p>
      </section>

      <main className="max-w-2xl mx-auto mt-10 space-y-4">
        {methods.map((m) => (
          <div key={m.label} className="rounded-2xl border border-white/10 bg-white/[0.02] p-6">
            <div className="flex items-center justify-between">
              <div className="text-lg md:text-xl tracking-[0.2em]" style={{ fontFamily: "var(--font-display)" }}>
                {m.label}
              </div>
              <button
                onClick={() => copy(m.account, m.label)}
                className="text-xs px-3 py-1 rounded-md border border-white/10 hover:border-[color:var(--gold)]"
              >
                {copied === m.label ? "COPIÉ" : "COPIER"}
              </button>
            </div>
            <div className="mt-4 space-y-1 text-sm">
              {m.bank && (
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Banque</span>
                  <span>{m.bank}</span>
                </div>
              )}
              <div className="flex justify-between">
                <span className="text-muted-foreground">{m.bank ? "N° de compte" : "Numéro"}</span>
                <span style={{ color: "var(--gold)" }}>{m.account}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Titulaire</span>
                <span>{m.holder}</span>
              </div>
            </div>
          </div>
        ))}

        <p className="text-center text-xs text-muted-foreground pt-4">
          Après paiement, présentez la preuve au comptoir.
        </p>
      </main>
    </div>
  );
}
