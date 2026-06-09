import { createFileRoute, Link } from "@tanstack/react-router";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/evenements")({
  component: Evenements,
  head: () => ({
    meta: [
      { title: "Événements — BALCONY LOUNGE " },
      { name: "description", content: "Découvrez les soirées de BALCONY LOUNGE." },
    ],
  }),
});

type EventItem = {
  id: string;
  title: string;
  date: string;
  description: string;
  image?: string;
};

const STORAGE_KEY = "cairo_events";

function Evenements() {
  const [events, setEvents] = useState<EventItem[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [title, setTitle] = useState("");
  const [date, setDate] = useState("");
  const [description, setDescription] = useState("");
  const [image, setImage] = useState("");

  useEffect(() => {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) setEvents(JSON.parse(raw));
    } catch {}
  }, []);

  const save = (next: EventItem[]) => {
    setEvents(next);
    localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
  };

  const addEvent = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title || !date) return;
    save([{ id: crypto.randomUUID(), title, date, description, image }, ...events]);
    setTitle("");
    setDate("");
    setDescription("");
    setImage("");
    setShowForm(false);
  };

  const remove = (id: string) => save(events.filter((ev) => ev.id !== id));

  const onFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => setImage(reader.result as string);
    reader.readAsDataURL(file);
  };

  return (
    <div className="min-h-screen bg-background text-foreground px-4 py-10 md:py-14">
      <header className="max-w-5xl mx-auto flex items-center justify-between">
        <Link to="/" className="text-xs tracking-[0.4em] text-muted-foreground hover:text-foreground">
          ← RETOUR
        </Link>
        <span className="text-xs tracking-[0.4em] text-muted-foreground">BALCONY</span>
      </header>

      <section className="text-center mt-10">
        <h1 className="text-4xl md:text-6xl italic" style={{ fontFamily: "var(--font-display)" }}>
          <span className="text-foreground">Nos </span>
          <span style={{ color: "var(--gold)" }}>Soirées</span>
        </h1>
        <p className="text-xs md:text-sm tracking-[0.4em] mt-4 text-muted-foreground">
          QUELLE AMBIANCE CHOISISSEZ-VOUS&nbsp;?
        </p>
      </section>

      <main className="max-w-3xl mx-auto mt-12 space-y-5">
        {events.length === 0 && !showForm && (
          <p className="text-center text-muted-foreground text-sm py-10">
            Aucune soirée pour l'instant. Ajoutez la première ci-dessous.
          </p>
        )}

        {events.map((ev) => (
          <article
            key={ev.id}
            className="group relative h-44 md:h-52 rounded-2xl overflow-hidden border border-white/10 bg-black"
          >
            {ev.image && (
              <img
                src={ev.image}
                alt={ev.title}
                className="absolute inset-0 w-full h-full object-cover opacity-60 group-hover:opacity-80 group-hover:scale-105 transition-all duration-700"
              />
            )}
            <div className="absolute inset-0 bg-gradient-to-r from-black/90 via-black/50 to-black/30" />
            <div className="relative h-full flex flex-col justify-end p-6 md:p-8">
              <div
                className="text-2xl md:text-3xl tracking-[0.15em] uppercase"
                style={{ fontFamily: "var(--font-display)" }}
              >
                {ev.title}
              </div>
              <div className="text-xs md:text-sm mt-1 tracking-[0.2em]" style={{ color: "var(--gold)" }}>
                {new Date(ev.date).toLocaleString("fr-FR", { dateStyle: "long", timeStyle: "short" }).toUpperCase()}
              </div>
              {ev.description && (
                <p className="text-sm text-white/70 mt-2 line-clamp-2 max-w-2xl">{ev.description}</p>
              )}
            </div>
            <button
              onClick={() => remove(ev.id)}
              className="absolute top-3 right-3 w-8 h-8 rounded-full bg-black/60 border border-white/20 text-xs text-white/70 hover:text-white hover:border-white/60"
              aria-label="Supprimer"
            >
              ✕
            </button>
          </article>
        ))}

        <div className="pt-6">
          {!showForm ? (
            <button
              onClick={() => setShowForm(true)}
              className="w-full rounded-2xl border border-dashed border-white/20 py-6 tracking-[0.3em] text-xs text-muted-foreground hover:text-foreground hover:border-[color:var(--gold)] transition"
            >
              + AJOUTER UNE SOIRÉE
            </button>
          ) : (
            <form
              onSubmit={addEvent}
              className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 space-y-4"
            >
              <h2 className="text-lg tracking-[0.2em]" style={{ fontFamily: "var(--font-display)" }}>
                NOUVELLE SOIRÉE
              </h2>
              <input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Nom de la soirée (ex: AFRO NIGHT)"
                className="w-full rounded-md bg-black/40 border border-white/10 px-4 py-3 outline-none focus:border-[color:var(--gold)]"
              />
              <input
                type="datetime-local"
                value={date}
                onChange={(e) => setDate(e.target.value)}
                className="w-full rounded-md bg-black/40 border border-white/10 px-4 py-3 outline-none focus:border-[color:var(--gold)]"
              />
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Description (DJ, dress code, infos...)"
                rows={3}
                className="w-full rounded-md bg-black/40 border border-white/10 px-4 py-3 outline-none focus:border-[color:var(--gold)]"
              />
              <div>
                <label className="block text-xs tracking-[0.3em] text-muted-foreground mb-2">
                  IMAGE D'AMBIANCE
                </label>
                <input
                  type="file"
                  accept="image/*"
                  onChange={onFile}
                  className="w-full text-sm text-muted-foreground file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:bg-white/10 file:text-white"
                />
                {image && (
                  <img src={image} alt="aperçu" className="mt-3 h-24 w-full object-cover rounded-md" />
                )}
              </div>
              <div className="flex gap-3">
                <button
                  type="button"
                  onClick={() => setShowForm(false)}
                  className="flex-1 rounded-md py-3 tracking-[0.3em] text-xs border border-white/10"
                >
                  ANNULER
                </button>
                <button
                  type="submit"
                  className="flex-1 rounded-md py-3 tracking-[0.3em] text-xs font-medium"
                  style={{ backgroundColor: "var(--gold)", color: "#000" }}
                >
                  AJOUTER
                </button>
              </div>
            </form>
          )}
        </div>
      </main>
    </div>
  );
}
