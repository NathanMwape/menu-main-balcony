import champDonOscartBlanc from "@/assets/champagne/don-oscart-blanc.jpg";
import champDonOscartBrut from "@/assets/champagne/don-oscart-brut.jpg";
import champDomPerignon from "@/assets/champagne/dom-perignon.jpg";
import champArmandDeBrignac from "@/assets/champagne/armand-de-brignac.jpg";
import champBelaireGold from "@/assets/champagne/Laurent perrier brut.jpeg";
import champBelaireLuxe from "@/assets/champagne/belaire-luxe.jpg";
import champBelaireRose from "@/assets/champagne/Laurent perrier rose.jpeg";
import champMoetBrut from "@/assets/champagne/moet-brut.jpg";
import champMoetIce from "@/assets/champagne/moet-ice.jpg";
import champMoetNectar from "@/assets/champagne/moet-nectar.jpg";
import champMoetNectarRose from "@/assets/champagne/moet-nectar-rose.jpg";
import champRuinartBlanc from "@/assets/champagne/ruinart-blanc.jpg";
import champRuinartBrut from "@/assets/champagne/ruinart-brut.jpg";
import champVeuveBrut from "@/assets/champagne/veuve-clicquot-brut.jpg";
import champVeuveRich from "@/assets/champagne/veuve-clicquot-rich.jpg";
import champVeuveRose from "@/assets/champagne/veuve-clicquot-rose.jpg";
import whBlackLabel from "@/assets/whisky/black-label.jpg";
import whBlueLabel from "@/assets/whisky/blue-label.jpg";
import whChivas12 from "@/assets/whisky/chivas-12.jpg";
import whChivas15 from "@/assets/whisky/chivas-15.jpg";
import whChivas18 from "@/assets/whisky/chivas-18.jpg";
import whDoubleBlack from "@/assets/whisky/double-black.jpg";
import whGlen12 from "@/assets/whisky/glenfiddich-12.jpg";
import whGlen15 from "@/assets/whisky/glenfiddich-15.jpg";
import whGlen18 from "@/assets/whisky/glenfiddich-18.jpg";
import whGlen21 from "@/assets/whisky/glenfiddich-21.jpg";
import whGoldLabel from "@/assets/whisky/gold-label.jpg";
import whGreenLabel from "@/assets/whisky/green-label.jpg";
import whJackDaniels from "@/assets/whisky/jack-daniels.jpg";
import whGentlemanJack from "@/assets/whisky/gentleman-jack.jpg";
import whJackHoney from "@/assets/whisky/jack-daniels-honey.jpg";
import whJameson from "@/assets/whisky/jameson.jpg";
import redlabel from "@/assets/whisky/RED LABEL.jpeg";
import bi33 from "@/assets/bieres/33-export.jpg";
import biCastel from "@/assets/bieres/castel.jpg";
import biBeaufort from "@/assets/bieres/beaufort.jpg";
import biGuinness from "@/assets/bieres/guinness.jpg";
import biSimba from "@/assets/bieres/simba.jpg";
import biTembo from "@/assets/bieres/tembo.jpg";
import biCastelLite from "@/assets/bieres/castel-lite.jpg";
import biBlackLabel from "@/assets/bieres/black-label.jpg";
import biHeineken from "@/assets/bieres/heineken.jpg";
import biLeffe from "@/assets/bieres/leffe.jpg";
import biCorona from "@/assets/bieres/corona.jpg";
import ciHunters from "@/assets/cider/hunters.jpg";
import ciSavanna from "@/assets/cider/savanna.jpg";
import ckCocktail from "@/assets/cocktails/cocktail.jpg";
import cgHennessyVs from "@/assets/cognac/hennessy-vs.jpg";
import cgHennessyVsop from "@/assets/cognac/hennessy-vsop.jpg";
import cgHennessyXo from "@/assets/cognac/hennessy-xo.jpg";
import cgMartellBs from "@/assets/cognac/martell-bs.jpg";
import cgMartellVs from "@/assets/cognac/martell-vs.jpg";
import cgMartellXo from "@/assets/cognac/martell-xo.jpg";
import cgDusse from "@/assets/cognac/dusse.jpg";
import cgRemyVs from "@/assets/cognac/remy martin XO.jpeg";
import cgRemyVsop from "@/assets/cognac/remy-vsop.jpg";
import giHendricks from "@/assets/gin/hendricks.jpg";
import giTanqueray from "@/assets/gin/tanqueray.jpg";
import lqJager from "@/assets/liqueur/jagermeister.jpg";
import lqManifest from "@/assets/liqueur/manifest.jpg";
import lqBaileys from "@/assets/liqueur/baileys.jpg";
import lqMartiniBlanc from "@/assets/liqueur/martini-blanc.jpg";
import lqMartiniRouge from "@/assets/liqueur/martini-rouge.jpg";
import lqMartiniRose from "@/assets/liqueur/martini-rose.jpg";
import lqKahlua from "@/assets/liqueur/kahlua.jpg";
import lqAmarula from "@/assets/liqueur/amarula.jpg";
import lqmalibu from "@/assets/liqueur/malibu.png";
import lqCointreau from "@/assets/liqueur/cointreau.jpg";
import sfDasani from "@/assets/soft/dasani.jpg";
import sfSucre from "@/assets/soft/sucre.jpg";
import sfCeres from "@/assets/soft/ceres.jpg";
import sfRedbull from "@/assets/soft/redbull.jpg";
import sfxxl from "@/assets/soft/xxl.jpg";
import tqAzul from "@/assets/tequila/azul.jpg";
import tqDj1942 from "@/assets/tequila/don-julio-1942.jpg";
import tqDjRepo from "@/assets/tequila/don-julio-reposado.jpg";
import tqOlmBlanco from "@/assets/tequila/olmeca-blanco.jpg";
import tqOlmGold from "@/assets/tequila/olmeca-gold.jpg";
import tqPatron from "@/assets/tequila/patron.jpg";
import vdAbsolut from "@/assets/vodka/absolut.jpg";
import vdBelvedere from "@/assets/vodka/belvedere.jpg";
import vdcirocSummer from "@/assets/vodka/ciroc summer.jpeg";
import vdcirocVodka from "@/assets/vodka/ciroc vodka.jpeg";
import vdGreyGoose from "@/assets/vodka/grey goose.jpeg";
import vnPinotage from "@/assets/vins/nederburg-pinotage.jpg";
import vnRose from "@/assets/vins/rendez-vous.jpg";
import vnSauvignon from "@/assets/vins/nederburg-sauvignon.jpg";
import vnMouton from "@/assets/vins/mouton-cadet.jpg";
import vnChandor from "@/assets/vins/chandor.jpg";

export type Item = { name: string; price: string; desc?: string; image?: string };
export type Category = { slug: string; label: string; desc: string; items: Item[] };

export const boireCategories: Category[] = [
  {
    slug: "champagne",
    label: "CHAMPAGNE",
    desc: "Bulles d'exception",
    items: [
      { name: "Don Oscart Blanc", price: "100 $", image: champDonOscartBlanc },
      { name: "Don Oscart Brut", price: "80 $", image: champDonOscartBrut },
      { name: "Don Pérignon", price: "400 $", image: champDomPerignon },
      { name: "Armand de Brignac", price: "800 $", image: champArmandDeBrignac },
      { name: "Laurent perrier brut", price: "130 $", image: champBelaireGold },
      { name: "Belaire Luxe", price: "100 $", image: champBelaireLuxe },
      { name: "Laurent perrier rose", price: "150 $", image: champBelaireRose },
      { name: "Moët Brut", price: "150 $", image: champMoetBrut },
      { name: "Moët Ice", price: "150 $", image: champMoetIce },
      { name: "Moët Nectar", price: "150 $", image: champMoetNectar },
      { name: "Ruinart Blanc", price: "300 $", image: champRuinartBlanc },
      { name: "Ruinart Brut", price: "200 $", image: champRuinartBrut },
      { name: "Veuve Clicquot Brut", price: "150 $", image: champVeuveBrut },
      { name: "Veuve Clicquot Rich", price: "180 $", image: champVeuveRich },


    ],
  },
  {
    slug: "whisky",
    label: "WHISKY",
    desc: "Single malt & blend",
    items: [
      { name: "Black Label", price: "70 $", image: whBlackLabel },
      { name: "Blue Label", price: "400 $", image: whBlueLabel },
      { name: "Chivas Regal 12y", price: "70 $", image: whChivas12 },
      { name: "Chivas Regal 18y", price: "150 $", image: whChivas18 },
      { name: "Double Black", price: "100 $", image: whDoubleBlack },
      { name: "Glenfiddich 12y", price: "100 $", image: whGlen12 },
      { name: "Glenfiddich 15y", price: "140 $", image: whGlen15 },
      { name: "Glenfiddich 18y", price: "180 $", image: whGlen18 },
      { name: "Glenfiddich 21y", price: "400 $", image: whGlen21 },
      { name: "Gold Label", price: "150 $", image: whGoldLabel },
      { name: "Jack Daniel's", price: "70 $", image: whJackDaniels },
      { name: "Jack Daniel Gentleman", price: "80 $", image: whGentlemanJack },
      { name: "Jameson", price: "50 $", image: whJameson },
      { name: "red label", price: "40 $", image: redlabel },
    ],
  },
  {
    slug: "cognac",
    label: "COGNAC",
    desc: "Élégance française",
    items: [
      { name: "Hennessy VS", price: "100 $", image: cgHennessyVs },
      { name: "Hennessy VSOP", price: "150 $", image: cgHennessyVsop },
      { name: "Hennessy XO", price: "400 $", image: cgHennessyXo },
      { name: "Martell BS", price: "120 $", image: cgMartellBs },
      { name: "Martell VS", price: "100 $", image: cgMartellVs },
      { name: "Rémy Martin XO", price: " 400 $", image: cgRemyVs },
      { name: "Rémy Martin VSOP", price: "150 $", image: cgRemyVsop },
    ],
  },
  {
    slug: "vodka",
    label: "VODKA",
    desc: "Pures & infusées",
    items: [
      { name: "Absolut", price: "50 $", image: vdAbsolut },
      { name: "Belvédère", price: "80 $", image: vdBelvedere },
      { name: "ciroc summer", price: "100 $", image: vdcirocSummer },
      { name: "ciroc Vodka", price: "100 $", image: vdcirocVodka },
      { name: "Grey Goose", price: "80 $", image: vdGreyGoose },
    ],
  },
  {
    slug: "tequila",
    label: "TEQUILA",
    desc: "Agave premium",
    items: [
      { name: "Azul", price: "500 $", image: tqAzul },
      { name: "Don Julio 1942", price: "550 $", image: tqDj1942 },
      { name: "Don Julio Reposado", price: "150 $", image: tqDjRepo },
      { name: "Olmeca Blanco", price: "80 $", image: tqOlmBlanco },
      { name: "Olmeca Gold", price: "80 $", image: tqOlmGold },
      { name: "Tequila Patrón", price: "100 $", image: tqPatron },
    ],
  },
  {
    slug: "gin",
    label: "GINS",
    desc: "Botaniques raffinés",
    items: [
      { name: "Hendrick's", price: "100 $", image: giHendricks },

    ],
  },
  {
    slug: "liqueur",
    label: "LIQUEUR",
    desc: "Digestifs & apéritifs",
    items: [
      { name: "Jägermeister", price: "70 $", image: lqJager },
      { name: "Jägermeister Manifest", price: "100 $", image: lqManifest },
      { name: "Baileys", price: "40 $", image: lqBaileys },
      { name: "Martini Blanc", price: "40 $", image: lqMartiniBlanc },
      { name: "Martini Rouge", price: "40 $", image: lqMartiniRouge },
      { name: "Martini Rose", price: "40 $", image: lqMartiniRose },
      { name: "Amarula", price: "40 $", image: lqAmarula },
      { name: "Malibu", price: "40 $", image: lqmalibu },
      { name: "cointreau", price: "50 $", image: lqCointreau },


    ],
  },
  {
    slug: "vins",
    label: "WINE",
    desc: "Rouge · Blanc · Rosé",
    items: [
      { name: "Nederburg Pinotage", price: "35 $", image: vnPinotage },
      { name: "Rendez-vous", price: "30 $", image: vnRose },
      { name: "Nederburg Sauvignon", price: "40 $", image: vnSauvignon },
      { name: "Mouton Cadet", price: "40 $", image: vnMouton },
      { name: "chandor", price: "30 $", image: vnChandor },
    ],
  },
  {
    slug: "cocktails",
    label: "COCKTAIL",
    desc: "Signature du chef",
    items: [
      { name: "Cocktail", price: "15 $", image: ckCocktail },
    ],
  },
  {
    slug: "bieres",
    label: "BIÈRES",
    desc: "Locales & importées",
    items: [
      { name: "33 Export", price: "6 $", image: bi33 },
      { name: "Castel", price: "6 $", image: biCastel },
      { name: "Beaufort", price: "6 $", image: biBeaufort },
      { name: "Guinness", price: "8 $", image: biGuinness },
      { name: "Simba", price: "6 $", image: biSimba },
      { name: "Tembo", price: "6 $", image: biTembo },
      { name: "Castel Lite", price: "8 $", image: biCastelLite },
      { name: "Black Label", price: "8 $", image: biBlackLabel },
      { name: "Heineken", price: "8 $", image: biHeineken },
      { name: "Leffe", price: "8 $", image: biLeffe },
      { name: "Corona", price: "8 $", image: biCorona },
    ],
  },
  {
    slug: "cider",
    label: "CIDER",
    desc: "Pommes pétillantes",
    items: [
      { name: "Hunters Gold", price: "6 $", image: ciHunters },
      { name: "Savanna", price: "6 $", image: ciSavanna },
    ],
  },
  {
    slug: "sans-alcool",
    label: "SOFT DRINK",
    desc: "Sans alcool",
    items: [
      { name: "Dasani", price: "2$", image: sfDasani },
      { name: "Sucré", price: "2 $", image: sfSucre },
      { name: "Jus Ceres", price: "10 $", image: sfCeres },
      { name: "Red Bull", price: "5 $", image: sfRedbull },
      { name: "xxl", price: "3 $", image: sfxxl },
    ],
  },
];

export const fumerAromes: Category[] = [
  {
    slug: "SHISHA NORMAL",
    label: "SHISHA NORMAL",
    desc: "Classique oriental",
    items: [
      { name: "SHISHA NORMAL", price: "15$",  },
    ],
  },
  {
    slug: "SHISHA MIXTE",
    label: "SHISHA MIXTE",
    desc: "Fraîcheur intense",
    items: [
      { name: "SHISHA MIXTE", price: "30$" }

    ],
  },
  {
    slug: "SHISHA SPECIALE",
    label: "SHISHA SPECILE",
    desc: "La spécialité ",
    items: [{ name: "SHISHA SPECIALE", price: "50$" }],
  },
];
