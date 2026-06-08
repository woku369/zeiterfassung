# Sake Science

Comprehensive guide to sake brewing, koji biochemistry, and related Japanese rice beverages. Based primarily on R. W. Atkinson's *The Chemistry of Sake-Brewing* (1881, Tokyo Daigaku), the first scientific study of sake production, supplemented by modern sources.

---

## §1 Overview

Sake (清酒, seishu) is a fermented rice beverage produced through a process fundamentally different from both beer and wine. Its defining characteristic is **multiple parallel fermentation** (並行複発酵, heiko fukuhakko): saccharification (starch → sugar) and alcoholic fermentation (sugar → alcohol) occur simultaneously in the same vessel. This allows sake to reach 13–20% ABV — far higher than beer (~5%) and comparable to wine — despite starting from a starch source.

Key distinctions from beer:
- **No malting**: instead of germinated barley, sake uses *koji* (Aspergillus oryzae mold grown on rice) for enzymatic conversion
- **No boil step**: the mash is never boiled; enzymes remain active throughout fermentation
- **Parallel processing**: saccharification and fermentation overlap rather than occurring sequentially
- **Enzyme product**: koji produces dextrose (glucose), not maltose — a fundamental biochemical difference from malt diastase
- **Higher alcohol**: parallel processing enables far greater alcohol yield from starch

Key distinctions from wine:
- **Starch source**: requires enzymatic conversion before yeast can ferment; grape must is already sugar
- **No added yeast** (traditional): ferment develops naturally from koji, rice, and environment during moto preparation
- **Still beverage**: finished sake contains no residual CO₂

Historical context: sake brewing likely originated in China and arrived in Japan via Korean immigrants around the 3rd century CE. By the 15th century, the districts of Itami, Ikeda, and Nishinomiya had established dominance. Around 300 years before Atkinson's writing (~1580s), the practice of heating sake for preservation was introduced — a form of pasteurization predating Pasteur's published work on wine by nearly three centuries.

Production scale (1880 data): Japan produced approximately 5 million koku of sake (≈900 million litres), plus 84,000 koku of shochu and 39,000 koku of mirin. This represented roughly 6 gallons per capita (vs. 34 gallons per capita beer consumption in England at the time).

---

## §2 Rice

### Rice varieties

Three main varieties exist in Japan:

| Variety | Japanese | Field type | Brewing use |
| --- | --- | --- | --- |
| Common rice | Uruchi (うるち) | Paddy | Standard brewing rice; universally used |
| Glutinous rice | Mochigome (もち米) | Paddy | Never used — produces sake that putrefies rapidly |
| Upland rice | Okaho | Dry | Reported to leave little residue; rarely used |

Best brewing rice (1881): Mino, Higo, Ise, Owari, Totomi, Hizen (first quality); Boshu, Tamba, Tajima (second); Kadzusa, Shimosa, Musashi, Kaga (third).

Modern sake-specific rice varieties (sakamai, 酒米) include Yamada Nishiki, Gohyakumangoku, Miyama Nishiki, and Omachi, bred for larger grain size, centered starch core (shinpaku), and lower protein.

### Rice composition

Analyses of hulled common rice (Atkinson, multiple samples):

| Component | Range (%) | Average (%) |
| --- | --- | --- |
| Water | 11.5–13.0 | 12.3 |
| Starch | 69.2–74.7 | 72.9 |
| Albumenoids (protein) | 4.3–5.6 | 5.1 |
| Sugar & dextrin | 1.5–6.5 | 3.3 |
| Cellulose | 2.4–3.3 | 2.8 |
| Fat | 0.9–1.9 | 1.2 |
| Ash | 0.1–1.2 | 0.5 |

After polishing/whitening (removing outer bran layers), composition shifts to approximately:

| Component | Whitened rice (%) |
| --- | --- |
| Starch | 82.1–82.3 |
| Albumenoids | 7.5–9.5 |
| Cellulose | 3.0–4.8 |

### Rice polishing (seimai, 精米)

Polishing ratio (seimai-buai, 精米歩合) indicates the percentage of the grain remaining after milling. Lower numbers = more polished = higher quality sake:

| Classification | Polish ratio | Result |
| --- | --- | --- |
| Table rice | ~92% | Minimal polishing |
| Futsushu (regular) | 70–73% | Standard sake |
| Tokubetsu | ≤60% | Special designation |
| Ginjo (吟醸) | ≤60% | Fruity, aromatic style |
| Daiginjo (大吟醸) | ≤50% | Premium; pronounced aromatics |
| Ultra-premium | 23–35% | Extreme polishing; some modern breweries |

Polishing removes fats, proteins, and minerals concentrated in the outer layers, which cause off-flavors and excessive enzymatic activity. The starch-rich core produces cleaner fermentation.

### Rice preparation

1. **Washing** (senmai): removes surface starch (nuka). Water absorption is timed precisely — over-soaking leads to cracking during steaming.
2. **Soaking** (shinseki): rice absorbs water to target ~30% moisture.
3. **Steaming** (mushimai): gelatinizes starch, making it accessible to koji enzymes. After steaming, rice contains approximately 38.8% water — the original 14% moisture plus ~40% absorbed weight. The grain should be firm on the outside, soft inside ("hineri-mochi" texture).

---

## §3 Koji (麹)

### Biology

Koji is rice inoculated with the mold Aspergillus oryzae (麹菌, koji-kin). The mold produces a suite of enzymes — primarily amylases, proteases, and lipases — that break down rice starch into fermentable sugars, proteins into amino acids (especially glutamic acid, the basis of umami), and fats into fatty acids and aromatic esters. This is the foundation of all sake brewing. Japan has designated A. oryzae its "National Mold."

**Domestication**: A. oryzae was domesticated from the toxic progenitor A. flavus at least 9,000 years ago in China. The two species share 99.5% of their genome — visual/phenotypic distinction is essentially impossible; reliable identification requires DNA sequencing. Through millennia of human selection, mycotoxin production has been bred out of A. oryzae entirely. Archaeological evidence from Jiahu, Henan province (7th millennium BCE) shows clay pottery with chemical residues of alcohol made from rice, honey, and fruit (McGovern et al., PNAS, 2004). Koji likely arrived in Japan during the Asuka period (538–710 CE); Buddhist monks established modern sake production methods during the 800s CE.

**Life cycle**: Spore → hyphae (filaments secreting extracellular enzymes to predigest substrate) → mycelium (dense hyphal mat) → conidiophores (reproductive structures) → spore release. The extracellular enzyme secretion is what makes koji useful: the mold digests starch and protein outside its cells, releasing sugars and amino acids into the surrounding substrate.

**Aspergillus species used in fermentation**:

| Species | Common name | Products | Notes |
| --- | --- | --- | --- |
| A. oryzae | Yellow koji | Sake, miso, shoyu, amazake, mirin, vinegar | No mycotoxins; strong amylase and protease |
| A. sojae | — | Some soy sauces, bean fermentation | High protease, low spore production |
| A. luchuensis | Brown koji | Barley shochu | High citric acid production; strong enzymes |
| A. luchuensis var. awamori | Black koji | Awamori (Okinawan spirit) | Produces citric acid; black spores; nearly went extinct in WWII |
| A. kawachi | White koji | Most modern shochu | 1923 mutation of black koji by Prof. Kawachi; high acid, no earthy aromas |

**Critical biochemical finding** (Atkinson): Koji extract converts maltose to dextrose (glucose), while malt extract cannot. This means the enzymatic pathway in sake is fundamentally different from beer. The koji enzyme system produces dextrose, not maltose, as its primary sugar product. This was confirmed by specific rotatory power measurements: at all stages of brewing, only dextrose was detected in solution — never maltose. Koji also produces large amounts of alpha-amylase specifically, creating more fermentable wort and lighter body than malt-derived beta-amylase (Shih & Umansky, 2020).

### Koji growth conditions

| Parameter | Value | Notes |
| --- | --- | --- |
| Growth temperature range | 21–35°C (70–95°F) | Prefers tropical conditions |
| Death threshold | Starts dying above 46°C (115°F); dead at 54°C (130°F) | Exothermic growth can self-heat past lethal point |
| Inoculation temperature | Max 37°C (100°F) | Higher kills spores |
| Protease-biased incubation | 26–30°C (80–86°F) | Lower temps favor protease (umami) production |
| Amylase-biased incubation | 32–35°C (90–95°F) | Warmer temps favor amylase (sugar) production |
| General recommendation | 30–35°C (86–95°F) | Sufficient enzymes for nearly any application |
| pH for growth | 6.0–7.8 | Below 5 or above 8.3 = culture death |
| pH for enzyme activity | 5.3–6.5 optimal | Below 3 or above 8.5 = reduced enzymatic activity |
| Total grow time | 36–48 hours | 36h for long-grain; 48h for medium-grain rice |

### Spore handling

- **Spore dispersal ratio**: 1 g spores to 10 g rice flour (or AP flour) — always disperse before use
- **Inoculation rate**: 1 g dispersed spore mixture per 1,000 g cooked substrate
- **Storage**: dispersed spores remain viable 18+ months in freezer in sealed jar with desiccant
- **Safety**: wear mask when handling undispersed spores (aspergillosis risk from concentrated inhalation). Never propagate your own spores — contamination with toxic Aspergillus species is possible and cannot be detected visually. Commercial producers test every batch microscopically for purity.
- **Recommended suppliers**: GEM Cultures (US); Higuchi Matsunosuke Shoten (Osaka, Japan — seven generations; maintains several hundred strains including sake-specific Hikami Ginjo and aromatic Kaori varieties)

### Koji preparation (traditional method)

**Facility**: Underground chambers built into clay (for thermal stability). The enclosed space maintains humidity and allows temperature management.

**Process timeline**:

| Day | Activity | Temperature |
| --- | --- | --- |
| 0 | Steamed rice spread on mats; koji-kin spores dusted over surface | Chamber: 27–28°C (80–83°F) |
| 1 | Rice gathered into mounds to retain heat; beginning of mycelial growth | Rising |
| 2 | Rice broken up and spread again; white fuzzy growth visible | ~35°C (95°F) |
| 3 | Koji reaches peak temperature; harvest when fully developed | 38–41°C (100–106°F) |

Temperature control is critical: too hot and the mold dies or produces off-flavors; too cool and growth stalls. Traditional brewers managed this entirely by hand feel, mound shape, and room ventilation. Mix every 12 hours and keep grain bed height to 2.5–3.8 cm (1–1.5 inches) to prevent overheating.

**Finished koji** characteristics:
- Weight increase: 100 parts common rice → 108 parts koji (8% gain from moisture and mycelium)
- Contains 30% water (vs. 14% in raw rice)
- White mycelium visible throughout grains
- Sweet chestnut/honeysuckle aroma
- Crumbly texture; grains should not be solid/wet
- **Sake-specific note**: koji for sake must be unsporulated — sporulated koji (visible green-yellow dusty surface) adds dank/musty off-flavors detectable in the delicate finished drink

### Koji preparation (modern home method)

For home brewers without a traditional muro (koji room):

1. Steam rice al dente (gaikou-nainan: firm surface, soft inside — forces mold to grow into grain, not just on surface)
2. Cool to below 37°C (100°F); spread on trays no more than 5 cm (2 inches) deep
3. Inoculate with dispersed spores; mix gently for several minutes
4. Cover tightly with plastic wrap; poke a couple finger-sized holes for air exchange
5. Incubate at 30°C (86°F) for general use, or 32–35°C (90–95°F) for amylase-biased sake koji
6. Ready in approximately 36–48 hours

**Incubation systems** (cheapest to most reliable):
- Oven with light on or pilot light (free; inconsistent)
- Styrofoam cooler with heating pad and wet towel (cheap; adequate)
- Water bath with aquarium heater (150W submersible) — reliable and affordable
- Immersion circulator in a cooler (most reliable home setup)
- Bread proofer set to 30°C with humidity control (dedicated; excellent)

**Koji storage** (Shih & Umansky):

| Method | Duration |
| --- | --- |
| Plastic wrap, refrigerated | ~2 weeks |
| Vacuum-sealed, refrigerated | 6 weeks |
| Vacuum-sealed, frozen | Up to 6 months |
| Dehydrated at 37°C (100°F) | Couple of months |
| Fresh, immediate use | Best quality |

Note: do not dehydrate above 73°C (165°F) — this denatures enzymes irreversibly.

### Enzyme activity

Koji produces three key enzyme classes:

| Enzyme class | Substrate | Products | Role in sake |
| --- | --- | --- | --- |
| **Amylases** (glucoamylase, alpha-amylase) | Starch (amylose, amylopectin) | Dextrose (glucose), dextrin | Primary saccharification; feeds yeast |
| **Proteases** | Proteins | Amino acids (esp. glutamic acid) | Yeast nutrition; umami depth |
| **Lipases** | Fats | Fatty acids, esters, alcohols | Aromatic compounds; fruity character |

Koji also produces **fruity esters** during saccharification — floral flavors and aromas similar to guava or tropical fruit. These esters are responsible for the subtle fruit character in sake, particularly ginjo styles. They are destroyed by boiling, which is why sake mash is never boiled.

**Action on starch**: Koji extract at room temperature converts gelatinized starch into dextrin and dextrose. Key findings from Atkinson's experiments:

| Temperature | Effect on koji extract |
| --- | --- |
| Below 45°C (113°F) | Minimal change in composition after 1 hour |
| 45–55°C (113–131°F) | Maximum enzyme activity; dextrin → dextrose conversion strongest at 55°C |
| 55–60°C (131–140°F) | Optimal range for both amylase and protease activity on substrate (amazake production temperature) |
| 60–70°C (140–158°F) | Solution becomes turbid; albumenoids (enzymes) precipitate |
| Above 73°C (165°F) | Enzyme denaturation complete; irreversible (Shih & Umansky) |

Note the distinction between **growth temperature** (30–35°C during koji cultivation) and **enzyme activity temperature** (55–60°C for maximum saccharification of a prepared koji extract). During sake brewing, enzymes work at mash temperature (often 10–25°C) — slower but sufficient because of the long fermentation period.

**Time vs. temperature trade-off**: At low temperature (10–12°C) for 18 hours, koji dissolves 29.2% of solid matter with 69.3% dextrose content. At 45°C for just 1 hour, it dissolves 31.8% of solid matter with 84.9% dextrose. However, longer contact at high temperature (2 hours at 45°C) dissolves more albumenoids (proteins), which is important for yeast nutrition.

**Action on sugars**: Koji extract also converts cane sugar (sucrose) and maltose into simpler sugars. Cane sugar is inverted; maltose is converted to dextrose. Malt extract cannot perform this maltose → dextrose conversion — this is a key biochemical distinction between koji-based and malt-based brewing.

---

## §4 Moto (酛) — Yeast Starter

The moto (literally "origin") is the yeast-propagation stage, analogous to making a yeast starter in beer brewing. Its purpose is to develop a healthy, vigorous yeast population before the main fermentation begins.

### Ingredients (per one moto)

| Ingredient | Itami | Nishinomiya | Tokyo (Atkinson) |
| --- | --- | --- | --- |
| Steamed rice | 0.50 koku | 0.50 koku | 0.40 koku |
| Koji | 0.20 koku | 0.50 koku | 0.16 koku |
| Water | 0.60 koku | 1.33 koku | 0.40 koku |

(1 koku = 180.4 litres; rice measured as dry rice before steaming/koji-making)

**Moto composition at mixing** (Tokyo brewery):
- Dry rice: 38.3% (containing 32.17% starch)
- Water: 61.7%

### Process

1. **Mixing** (Day 0): Rice, koji, and water combined in six shallow wooden tubs (hangiri, capacity 0.267 koku each). Mass is thoroughly mixed by hand for 2 hours, breaking all lumps. Initially very thick; becomes thin as koji enzymes begin working.

2. **Cold saccharification** (Days 1–5): Mixture held at low temperature (0–10°C). Koji enzymes slowly convert gelatinized starch to dextrose and dextrin. After 24 hours, paddle stirring (kai-ire) begins. Contents transferred to a larger covered tub (moto-oroshi), insulated with matting.

3. **Heating** (Day 5): A conical closed tub (nubume/daki, 18" tall, 12" top diameter, 9–10" bottom) filled with boiling water is lowered into the mash and moved about to heat it. At Itami, 5–9 heaters used over 13 days; at Nishinomiya, 10–13 heaters.

4. **Active fermentation** (Days 5–14): Heating induces rapid yeast development. Fermentation proceeds vigorously with visible effervescence and pungent odor.

### Moto composition over time

| Day | Dextrose (%) | Dextrin (%) | Alcohol (%) | Temp (°C) | Undissolved starch (%) |
| --- | --- | --- | --- | --- | --- |
| 3 | 7.35 | 5.12 | 0 | 13 | 20.43 |
| 5 | 12.25 | 5.69 | 0 | 10 | 15.46 |
| 7 | 5.4 | 7.0 | 5.2 | 23 | 10.68 |
| 10 | 0.99 | 2.81 | 8.61 | 14 | 12.46 |
| 12 | 0.49 | 2.72 | 9.41 | 10 | 11.55 |
| 14 | 0.50 | 2.57 | 9.20 | 9 | 12.05 |

**Key observations**:
- By Day 3, only dextrose is present in solution — no maltose detected (rotatory power 124° observed vs. 123.4° calculated for dextrose + dextrin)
- Between Days 5 and 7, alcohol jumps from 0 to 5.2% as heating triggers yeast activity
- Dextrose is rapidly consumed once fermentation begins; less than 1% by Day 10
- Dextrin stabilizes around 2.8% from Day 10 onward — koji appears to lose activity by this point
- Temperature peaks at 23°C on Day 7, then falls as sugar supply decreases

**Finished moto** (Nishinomiya): 10.5% alcohol, 2% dextrose, 0.56% total acid, 16.58% starch/cellulose.

**Taste progression at Itami** (13 days):
- Day 3: sweet (high dextrose)
- Day 6: astringent
- Day 7: slightly alcoholic
- Final: sour, with five recognizable flavors — sweet, sour, bitter, astringent, and alcoholic (sour, bitter, and astringent most pronounced)

**Acid formation**: Succinic acid forms during fermentation; lactic acid develops during cooling in shallow vessels. The acidity is self-limiting because yeast growth dominates.

---

## §5 Principal Brewing Process (Moromi)

The main fermentation is a staged process of progressive additions. In Itami and Nishinomiya, three distinct stages are recognized: **soye** (添, soe), **naka** (仲), and **shimai** (留, tome). Each stage adds fresh steamed rice, koji, and water to the moto.

### Stage 1: Soye (first addition)

Moto plus fresh ingredients placed in a large tun (sanjaku-oke, "three-foot tub," ~8 koku capacity, half-filled).

| Ingredient | Itami | Nishinomiya |
| --- | --- | --- |
| Moto | 1.30 koku | 1.33 koku |
| Steamed rice | 1.30 koku | 1.05 koku |
| Koji | 0.35 koku | 0.35 koku |
| Water | 1.30 koku | 1.15 koku |

- Stirred every 2 hours
- Duration: 42 hours (Itami) to 3 days (Nishinomiya)
- Temperature rises to 20°C (air temp 11°C)
- Pungent, fragrant odor

Soye composition (Nishinomiya): 11% alcohol, 0.18% dextrose, 17.52% starch remaining.

### Stage 2: Naka (second addition)

Soye divided into two portions, each placed in a three-foot tub. Fresh rice, koji, and water added.

| Ingredient | Itami | Nishinomiya |
| --- | --- | --- |
| Soye | 4.25 koku | 3.88 koku |
| Steamed rice | 2.00 koku | 1.80 koku |
| Koji | 0.65 koku | 0.60 koku |
| Water | 3.00 koku | 2.40 koku |

- Stirred every 2 hours to prevent rice settling beyond koji's reach
- Duration: 24 hours
- Temperature: ~15.5°C (observed soon after mixing)
- Pungent, fragrant odor (less intense than soye)

### Stage 3: Shimai (final addition)

Naka divided again (now in four tubs, each containing one-quarter of original moto). Final addition of rice, koji, and water.

| Ingredient | Itami | Nishinomiya |
| --- | --- | --- |
| Naka | 9.90 koku | 8.68 koku |
| Steamed rice | 3.30 koku | 3.60 koku |
| Koji | 1.00 koku | 1.20 koku |
| Water | 4.20 koku | 6.20 koku |

- Water quantity at this stage determines final alcoholic strength
- After ~3 days, contents collected into one large tub (roku-shaku-oke, 24–25 koku capacity)
- Vigorous fermentation for 2–3 days, then gradually ceases
- Froth sinks; liquid becomes strongly alcoholic

### Total materials used per moto

| Stage | Rice (steaming) | Rice (koji) | Water |
| --- | --- | --- | --- |
| Moto | 0.50 koku | 0.20 koku | 0.60 koku |
| Soye | 1.30 | 0.35 | 1.30 |
| Naka | 2.00 | 0.65 | 3.00 |
| Shimai | 3.30 | 1.00 | 4.20 |
| **Total (Itami)** | **7.10** | **2.20** | **9.10** |

Overall composition: 33.4% dry rice (28.05% starch), 66.6% water (Itami); 32.3% dry rice (27.13% starch), 67.7% water (Nishinomiya).

### Fermentation monitoring (Tokyo brewery)

| Day | Alcohol (%) | Dextrose (%) | Dextrin (%) | Temp (°C) | Starch (%) | Sp. gravity |
| --- | --- | --- | --- | --- | --- | --- |
| 17 | 5.80 | 2.06 | 3.89 | 19 | 12.81 | 1.030 |
| 19 | 9.44 | 1.16 | 2.74 | 25 | 7.85 | 1.017 |
| 21 | 11.83 | 0.27 | 1.42 | 26 | 5.53 | 0.994 |
| 24 | 12.41 | 0.27 | 0.47 | 20 | 5.40 | 0.990 |
| 28 | 13.23 | 0 | 0.41 | 12 | 4.18 | 0.988 |

**Key observations**:
- Peak fermentation temperature: 26°C on Day 21 (air temp never above 12°C — heat is entirely from fermentation)
- No maltose detected at any stage — rotatory power measurements confirm only dextrose and dextrin
- Starch dissolution is continuous; koji diastase remains active throughout
- Sugar conversion to alcohol is faster than starch dissolution — dextrose never accumulates
- Alcohol still increasing between Days 24 and 28 despite near-zero residual sugar — fresh starch is being dissolved and immediately fermented
- Fixed acid (mostly succinic) increases steadily; less than in moto due to reduced lactic acid formation

---

## §6 Fermentation Microbiology

### Yeast development in moto

| Day | Microscopic observation | Yeast cell size |
| --- | --- | --- |
| 1–2 | No special features | — |
| 3 | Isolated ferment cells amid broken mycelium fragments | Largest: 0.0075 mm |
| 5 | Few more cells; fragments of mycelium | Similar |
| 7 | Active budding and growth; vigorous fermentation | Largest: 0.0083 mm; avg: 0.0076 mm |
| 10 | Similar to Day 7; cells fresh and vigorous | ~0.008 mm |
| 12 | Cells vigorous despite 10°C temp; minute cells of unknown function observed | ~0.008 mm |
| 14 | Cells unchanged; some mycelium fragments | Largest: 0.0082 mm |
| 17+ | Very active growth after rice/koji addition; temperature 19°C+ | Largest: 0.0075 mm (not fully grown) |
| 19+ | Full-grown cells, peak fermentation | ~0.008 mm |

### Sake yeast characteristics

- **Size**: approximately 0.0075–0.0083 mm, smaller than beer yeast (Saccharomyces cerevisiae, never below 0.008 mm)
- **Shape**: spherical to oval, with small internal vacuoles
- **Reproduction**: budding (same as beer/wine yeasts)
- **Origin**: develops naturally in the mash; not intentionally inoculated in traditional brewing. Yeast cells appear as early as Day 3, likely introduced via koji, rice, equipment surfaces, and/or ambient environment. Warming triggers rapid multiplication.
- **Comparison**: sake fermentation more closely resembles wine than beer — high final alcohol, natural yeast inoculation, and the specific yeast species differs from S. cerevisiae in size and morphology

Modern identification: the principal sake yeast is classified as Saccharomyces cerevisiae (strains specific to sake, such as Kyokai No. 7, No. 9, No. 14, etc.), though Atkinson's measurements suggest morphological differences from beer strains. The Brewing Society of Japan maintains and distributes standard sake yeast strains.

### Other organisms

- **Mucor species** (M. mucedo, M. racemosus): can produce alcohol when submerged in sugar solution, but yield only 2–4% ABV — insufficient for sake production
- **Lactic acid bacteria**: present during moto preparation (especially during cooling in shallow vessels); contribute to the sour character of finished moto. In the main fermentation, their growth is suppressed by alcohol and active yeast competition
- **Contamination risks**: if acid ferments develop before alcoholic ferments gain dominance (e.g., from heating mash too rapidly), the brew can fail

---

## §7 Filtration and Yield

### Pressing

At the end of fermentation, the mash (moromi) is pressed through a wooden press called **fune** (船).

**Equipment**: A wooden box covered by a plate pressed down via a lever hinged to a ground post, weighted at the free end with 540–815 kg (1,200–1,800 lbs). Filtered liquid escapes through an aperture at the bottom front.

**Process**:
1. Mash placed into long hempen bags strengthened with persimmon juice (kaki-no-shibu)
2. Each bag filled about two-thirds full (~3.5 sho)
3. 300–500 bags piled in the press (Itami: 4 presses holding 342–400 bags each; Nishinomiya: 500 bags)
4. Initial pressing uses very light weight (heavy pressure initially produces turbid filtrate)
5. Weight increased to full (540–815 kg) for 12 hours
6. Bags turned over; full pressure renewed for another 12 hours
7. Filtrate is slightly turbid; requires clarification before use

### Filtered sake composition

| Component | Percentage |
| --- | --- |
| Alcohol | 11.14 |
| Glycerin, resin, albumenoids | 1.992 |
| Fixed acid | 0.13 |
| Volatile acid | 0.02 |
| Water | 86.718 |
| Specific gravity | 0.990 |

### Pressed residue (kasu, 粕)

| Component | Percentage |
| --- | --- |
| Soluble solid matter | 1.43 |
| Starch and cellulose | 32.07 |
| Ash | 0.70 |
| Alcohol | 6.00 |
| Water | 59.80 |

The 6% alcohol remaining in the kasu is recovered by distillation to produce shochu (see §10).

### Alcohol yield efficiency

From the Tokyo brewery data:
- Total dry rice used: 175.1 kuwamme (containing 84% starch = 147.1 kw starch)
- Theoretical maximum alcohol from all starch: 80 kw
- Actual alcohol produced: 39.8 kw (36.32 kw in sake + 3.48 kw in kasu)
- **Yield efficiency: 49.75%** of theoretical maximum

Losses occur from:
- Rice cleaning and washing
- Incomplete starch conversion
- CO₂ loss during fermentation
- Alcohol evaporation during multiple vessel transfers
- Alcohol retained in pressed residue

---

## §8 Preservation

### Clarification (ori-biki)

Fresh-pressed sake is turbid. Clarification by settling:

1. Sake collected in large tuns with two holes near the bottom (one above the other), closed by plugs
2. After ~15 days, suspended matter settles
3. Clear liquid drawn off via upper plug
4. Remainder settles longer; drawn off via lower plug
5. Final sediment (ori, 滓) added to the next brew before filtering — acts as fining agent

### Pasteurization (hi-ire, 火入れ)

Traditional heating to prevent spoilage — a practice documented in Japan approximately 300 years before Pasteur's work on wine preservation (1866).

**Method**:
- Large iron pan built into the ground, heated by wood fire from below
- Sake heated to 49–54°C (120–130°F)
- Traditional temperature test: a workman dips his hand in three times in succession without much discomfort
- Hot sake transferred to storage vats immediately

**Storage**: Large tuns (40 koku ≈ 7,200 litres) of sugi (Cryptomeria japonica) or hinoki (Chamaecyparis obtusa), closed with lids and sealed with seaweed-based glue (funori).

**Limitations**: sake keeps well in cold weather but requires re-examination during summer. Signs of spoilage require removing sake from tuns and re-heating. Spoilage produces butyric acid, ammonia, and volatile off-flavors.

Atkinson recommended the adoption of Pasteur's method (controlled-temperature heating in sealed bottles) for more reliable preservation.

### Finished sake composition

Multiple samples from Itami and Nishinomiya (1879–80 vintage, heated once):

| Property | Range |
| --- | --- |
| Alcohol | 11–14% |
| Dextrose | Very small (trace) |
| Dextrin | Very small (trace) |
| Total acid | 0.3–0.6% |
| Specific gravity | ~0.99 |
| CO₂ | None (still) |

Appearance: pale straw color when new; darkens with age and especially after heating. Taste: develops with maturation; newly-made sake has an "unripe" character.

---

## §9 Modern Sake Categories

Modern sake classification uses a system based on rice polishing ratio, the addition (or not) of distilled alcohol, and other production choices.

### By designation (tokutei meishoshu, 特定名称酒)

| Category | Polish ratio | Alcohol addition | Character |
| --- | --- | --- | --- |
| Junmai Daiginjo | ≤50% | None | Most premium; fruity, complex |
| Daiginjo | ≤50% | Small amount | Aromatic, refined |
| Junmai Ginjo | ≤60% | None | Fruity, balanced |
| Ginjo | ≤60% | Small amount | Fragrant, light |
| Tokubetsu Junmai | ≤60% or special method | None | Distinctive character |
| Tokubetsu Honjozo | ≤60% or special method | Limited | Light, versatile |
| Junmai | No requirement | None | Full-bodied, rice-forward |
| Honjozo | ≤70% | Limited | Clean, easy-drinking |

- **Junmai** (純米) means "pure rice" — no added alcohol
- Added alcohol (jozo alcohol) is limited to 10% of rice weight for premium categories; lightens flavor and enhances aromatics
- **Futsushu** (普通酒, "ordinary sake") falls outside these designations; may have more added alcohol and other additions

### By style/treatment

| Style | Description |
| --- | --- |
| Nama (生) | Unpasteurized; fresh, lively character; must be refrigerated |
| Namazume | Pasteurized once (before storage only); not again before bottling |
| Nigori (にごり) | Coarsely filtered; cloudy/milky appearance; sweet and textured |
| Genshu (原酒) | Undiluted; typically 17–20% ABV (vs. standard ~15%) |
| Koshu (古酒) | Aged sake; amber color, sherry-like complexity |
| Sparkling | Carbonated (natural or forced); growing modern category |
| Kimoto (生酛) | Traditional moto method using natural lactic fermentation |
| Yamahai (山廃) | Simplified kimoto; omits pole-ramming (yama-oroshi); richer body |
| Sokujo (速醸) | Modern moto method; lactic acid added directly for faster production |

---

## §10 Shochu (焼酎) — Distilled Rice Spirit

Shochu is a distilled spirit traditionally made by recovering alcohol from sake lees (kasu), though it is now produced from various base materials.

### Traditional production from kasu

**Still design**: A simple apparatus consisting of:
- Shallow iron basin (boiler) built over a wood fireplace
- Wooden cylinder (tub) with perforated bottom resting on the basin; 28" diameter × 26" height (Itami)
- Iron condenser basin on top (24" diameter), terminating below in a point above a flat funnel leading to a receiver
- Cold water in the condenser serves as condensing surface; changed several times during operation

**Process**:
1. 10 kuwamme of pressed residue (kasu) mixed with 1.1 kw of rice husks (for porosity)
2. Mixture placed in the wooden tub on hempen cloth over perforated bottom
3. Boiler filled with water; tub placed on basin; junction sealed with a straw ring
4. Condenser placed on top and filled with cold water
5. Fire lit; steam rises through kasu mixture, carrying alcohol vapors
6. Vapors condense on the underside of the cold basin, drip to the point, into the funnel, and out to the receiver
7. Operation lasts approximately 1 hour
8. Condenser water changed multiple times

**Strength** depends on the number of condenser water changes (more changes = weaker spirit, larger volume):

| Type | Condenser changes | Volume name | Alcohol (%) |
| --- | --- | --- | --- |
| Strong | 2.5 | San-jo-dori (3-sho collection) | 41–50 |
| Medium | 3 | Go-jo-dori (5-sho collection) | 37–44 |
| Weak | 4.5 | Shichi-jo-dori (7-sho collection) | 26–37 |

Shochu analyses (Atkinson):

| Sample | Origin | Alcohol (%) | Sp. gravity |
| --- | --- | --- | --- |
| Kansei | Itami (5-sho-dori) | 50.2 | 0.918 |
| Tyo | — | 36.99 | 0.942 |
| Awomori | — | 43.47 | 0.937 |
| Hachiobori | — | 41.5 | 0.941 |
| 3-sho-dori | Itami | 26.00 | 0.964 |

Note: spoiled sake was also distilled by using it in the boiler instead of water. Residue after distillation was sold as manure.

### Modern shochu

Modern shochu is classified into two types:
- **Honkaku shochu** (本格焼酎, "authentic"): single distillation in a pot still; retains base material character. Can be made from barley (mugi), sweet potato (imo), rice (kome), buckwheat (soba), brown sugar (kokuto), or other materials.
- **Korui shochu** (甲類): multiple distillation; neutral spirit; used for mixing and as base for chuhai

Typical ABV: 25% (standard) or 20% (light). Maximum allowed: 45%.

**Koji species for shochu**: Unlike sake (which uses yellow A. oryzae exclusively), shochu production uses acid-producing koji species that protect the mash in warmer southern Japanese climates:

| Koji type | Species | Use | Character |
| --- | --- | --- | --- |
| Yellow (kiku-koji) | A. oryzae | Sake, rice shochu | Low acid; clean flavor |
| Black (kuro-koji) | A. luchuensis var. awamori | Awamori (Okinawan); some shochu | High citric acid; robust, earthy |
| White (shiro-koji) | A. kawachi | Most modern shochu | High citric acid; clean, no earthy aromas |
| Brown | A. luchuensis | Barley shochu | High citric acid; strong enzymes |

White koji (A. kawachi) was discovered in 1923 as a natural mutation of black koji by Professor Genichiro Kawachi. Its clean flavor profile without the earthy aromas of black koji made it the preferred choice for most modern shochu production.

---

## §11 Mirin (味醂) — Sweet Rice Liqueur

Mirin is a sweet cooking wine/liqueur made by fermenting steamed glutinous rice (mochigome) and koji in shochu. The high initial alcohol suppresses yeast activity, preserving sweetness.

### Composition (Atkinson, multiple samples)

| Component | Range (%) | Typical (%) |
| --- | --- | --- |
| Alcohol | 10.0–18.5 | 12–14 |
| Dextrose | 17.8–30.1 | 19–22 |
| Dextrin etc. | 0.8–10.5 | 3–5 |
| Water | 55.0–67.4 | 61 |

Key characteristics:
- Much sweeter than sake due to high residual sugar (koji converts starch but alcohol inhibits fermentation)
- Used extensively in Japanese cooking (teriyaki, simmered dishes)
- Traditionally consumed as a New Year's drink
- Some varieties flavored with plum juice (ume) or scented herbs (shiso)

### Modern mirin categories

| Type | Alcohol | Sugar | Tax status |
| --- | --- | --- | --- |
| Hon mirin (本みりん) | ~14% | ~40–50% | Liquor tax applies |
| Shio mirin (塩みりん) | ~14% + 1.5% salt | ~40% | No liquor tax (salt makes it undrinkable) |
| Mirin-fu chomiryo | <1% | Variable | Seasoning, not alcoholic |

---

## §12 Amazake (甘酒) — Sweet Rice Drink

Amazake ("sweet sake") is likely the discovery that led to sake itself. It is an unfermented (or lightly fermented) sweet rice drink made by incubating cooked rice with koji at saccharification temperature. When yeast naturally colonizes amazake, alcoholic fermentation begins — the origin of sake.

### Sweet amazake

| Ingredient | Ratio |
| --- | --- |
| Cooked starch (rice) | 1 part |
| Koji | 1 part |
| Water | 2 parts |

Blend ingredients to increase surface area. Hold at 55–60°C (131–140°F) for 10–14 hours. The result is a thick, intensely sweet porridge — koji amylases convert nearly all starch to glucose at this temperature. Store airtight and refrigerated. Heating above 73°C (165°F) halts enzyme activity but also denatures enzymes — use cold storage if further enzymatic activity is desired.

### Sour amazake

Same ratio but with 4 parts water instead of 2. After saccharification, strain and hold at ambient temperature exposed to air, stirring daily, for up to 1 week. Naturally occurring Lactobacillus acidifies the liquid.

### Shio koji (塩麹) — Salt koji

Not a beverage, but a fundamental koji-based seasoning/marinade:

| Ingredient | Amount |
| --- | --- |
| Koji | 1 part |
| Water | 1 part |
| Salt | 5% of total weight |

Blend to increase surface area. Ferment at ambient temperature, mixing 1–2× daily for 7 days. Salt range: 2–7% (below 2% risks pathogen growth; above 7% inhibits beneficial microbes). Store airtight and refrigerated.

---

## §13 Practical Notes for Home Sake Brewing

### Equipment

- **Steaming**: bamboo steamer basket or colander over boiling water; rice must not contact water
- **Koji production**: incubation chamber maintaining 30–36°C and high humidity (styrofoam cooler with heating pad works for small batches)
- **Fermentation vessel**: food-grade bucket or wide-mouth carboy; must allow stirring access
- **Pressing**: fine mesh bag (nylon paint strainer or nut milk bag) in a colander, or a fruit press

### Simplified process outline

1. **Polish and wash rice** (use short-grain or calrose; true sakamai if available)
2. **Steam rice** — spread on clean cloth over boiling water, steam 45–60 minutes until translucent and chewy
3. **Make koji** — inoculate cooled steamed rice (~35°C) with koji-kin spores; incubate 42–48 hours at 30–36°C, breaking up once at ~24 hours. Target: sweet chestnut smell, white fuzzy growth throughout.
4. **Make moto** — combine koji, steamed rice, and water; hold cold (5–10°C) for several days, then allow to warm to ~20°C for fermentation to start. Modern method: add a pinch of lactic acid at the start (sokujo method) to suppress bacteria.
5. **Three-stage additions** (sandan-jikomi) — add more steamed rice, koji, and water in three batches over 4 days:
   - Day 1: first addition (soe)
   - Day 2: rest (odori, "dancing" — fermentation catches up)
   - Day 3: second addition (naka)
   - Day 4: third addition (tome)
6. **Ferment** — maintain 15–18°C for ginjo-style (more aromatic), 18–22°C for junmai-style (fuller body). Stir daily for first week. Total fermentation: 18–32 days.
7. **Press** — strain through fine mesh bags; squeeze gently
8. **Settle** — let pressed sake rest 1–2 weeks; rack off sediment
9. **Pasteurize** (optional) — heat to 60–65°C in a water bath; bottle immediately. Skip for nama-style (unpasteurized; must refrigerate).

### Common issues

| Problem | Likely cause | Solution |
| --- | --- | --- |
| Moto won't start fermenting | Too cold; insufficient yeast | Warm to 20°C; add small amount of commercial sake yeast (Wyeast 4134 or similar) |
| Sour/vinegary taste | Bacterial contamination | Ensure all equipment sanitized; add lactic acid at moto stage; maintain good yeast health |
| Stuck fermentation | Temperature too low; nutrient depletion | Warm gradually; add koji or yeast nutrient |
| Sake too sweet | Insufficient fermentation time | Allow longer fermentation; ensure yeast viability |
| Off-flavors (sulfur, solvent) | Stressed yeast; high temperature | Ferment cooler; ensure adequate nutrition |
| Turbid/cloudy | Normal — will settle; press more thoroughly | Allow longer settling; fine with bentonite if desired |

---

## §14 Water

Traditional breweries prized their water sources. The water of Nishinomiya (宮水, miyamizu) is particularly famous for its mineral content, which promotes vigorous fermentation. Key water characteristics:

- **Hard water** (Nishinomiya-style): higher potassium, phosphorus, and calcium; promotes active fermentation and produces dry (karakuchi) sake
- **Soft water** (Fushimi-style): lower mineral content; slower fermentation; produces sweeter (amakuchi) sake. Requires more careful technique.

The Japanese brewer's traditional term for water quality is "mizu no sei" (水の性, "character of the water").

---

## §15 References

- Atkinson, R. W. *The Chemistry of Sake-Brewing*. Memoirs of the Science Department, Tokio Daigaku (University of Tokyo), No. 6. Published by Tokio Daigaku, 1881.
- Shih, Rich, and Jeremy Umansky. *Koji Alchemy: Rediscovering the Magic of Mold-Based Fermentation*. Chelsea Green Publishing, 2020.
- Korschelt, O. "On Sake." *Transactions of the German Asiatic Society of Japan*, December 1878.
- McGovern, Patrick E. et al. "Fermented beverages of pre- and proto-historic China." *Proceedings of the National Academy of Sciences* 101(51), 2004.
- Pasteur, L. *Études sur le Vin*. 1873.
