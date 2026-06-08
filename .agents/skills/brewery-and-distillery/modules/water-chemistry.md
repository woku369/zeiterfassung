# Water Chemistry Module

**Sources**:
- *Water: A Comprehensive Guide for Brewers* by John Palmer and Colin Kaminski (Brewers Publications, 2013) -- extensively referenced throughout, including Chapters 1-7 and Appendices B-D
- *Water Chemistry for Brewers* (Precision Fermentation eBook, 2022)
- Martin Brungard (Bru'n Water creator, Brewers Association technical advisor)
- Professional brewer interviews (New Belgium, Cigar City, Trillium, Stone, Lawson's Finest)

---

> **IMPORTANT — Practical output format**: When recommending water adjustments for a recipe, always express additions as **masses or volumes of actual brewing salts and acids** (e.g., "add 4 g gypsum and 3 g calcium chloride to 7 gallons total water"), not as target ion concentrations in ppm. Target ppm values are useful for understanding water profiles, but a brewer standing at their kettle needs to know how many grams of gypsum to weigh out, not that they need "150 ppm sulfate." When providing water adjustment recommendations, include: (1) the salt/acid name, (2) the mass in grams (and teaspoons where helpful — 1 tsp gypsum ≈ 4 g, 1 tsp CaCl₂ ≈ 3.4 g), (3) the total water volume the addition applies to, and (4) when to add it (mash vs. sparge vs. boil). You may optionally include the resulting ion profile for reference, but the actionable addition amounts must come first.

---

## 1. Why Water Chemistry Matters

Water comprises up to 97% of a beer's volume, yet water quality is often overlooked. As Martin Brungard notes: "I know of a brewer who'd won several World Beer Cup gold medals for one particular beer but the rest of his beers were just terrible. When brewers pay a little bit of attention to their water then their full repertoire of beers improves tremendously."

**Key principle**: Know your water source and what to expect from it. One supplier may draw from multiple sources (wells, rivers, springs), and each source varies in chemical composition—even fluctuating with weather.

---

## 2. How Water Develops Its Chemistry

Water picks up minerals as it contacts and permeates rock and soil. When minerals dissolve, they become **ions** (charged particles).

### Water Hardness

**Hard water** (high calcium/magnesium):
- Common in American west and midwest
- Caused by limestone and gypsum geological formations
- Suits stouts, porters, amber ales

**Soft water** (low minerals):
- Common in mountain and coastal regions
- Caused by granite and sandstone geology
- Suits pilsners, light lagers

**Important**: Both hard and soft water can produce excellent beer. The key is matching water profile to beer style.

### Hardness vs. Alkalinity: The Deeper Distinction

Palmer and Kaminski emphasize that brewers must distinguish between **hardness** and **alkalinity** -- they are related but separate concepts.

**Hardness** is defined as the sum of calcium and magnesium ion concentrations, expressed as CaCO3:

```
Total Hardness (as CaCO3) = 50 * ([Ca]/20 + [Mg]/12.1)
```

**Alkalinity** is the buffering capacity of the water against acid -- specifically, the amount of strong acid (in mEq/L) required to convert all carbonate and bicarbonate to carbonic acid at pH 4.3.

**Temporary hardness** vs. **permanent hardness**:
- **Temporary hardness**: The portion of calcium/magnesium hardness that can be removed by boiling (it combines with bicarbonate and precipitates as CaCO3). If alkalinity as CaCO3 is greater than hardness as CaCO3, then all of the hardness is temporary.
- **Permanent hardness**: The portion remaining after boiling. If hardness as CaCO3 exceeds alkalinity as CaCO3, the excess is permanent hardness (associated with sulfate and chloride salts rather than bicarbonate).

**Key point from Palmer/Kaminski**: "One thing we need to remember as brewers is that we are trying to control or reduce alkalinity, not hardness. Many advertisements for common water treatment processes talk about removing temporary hardness or reducing permanent hardness as the goal. As brewers, we usually don't want to reduce or remove hardness from our brewing water -- just alkalinity."

### Conversion Factors for Water Reports

Water reports express ions in various units. Key conversions (Palmer/Kaminski, Table 4):

| To Get | From | Do This |
|--------|------|---------|
| Ca (mEq/L) | Ca (ppm) | Divide by 20 |
| Mg (mEq/L) | Mg (ppm) | Divide by 12.1 |
| HCO3 (mEq/L) | HCO3 (ppm) | Divide by 61 |
| Ca (ppm) | Ca Hardness as CaCO3 | Divide by 50, multiply by 20 |
| Mg (ppm) | Mg Hardness as CaCO3 | Divide by 50, multiply by 12.1 |
| HCO3 (ppm) | Alkalinity as CaCO3 (at pH 8-8.6) | Divide by 50, multiply by 61 |
| Alkalinity as CaCO3 | HCO3 (ppm) | Multiply by 50/61 |

### Water Charge Balance

Palmer/Kaminski (Appendix D) explain that a water report can be quality-checked by verifying electrical charge balance: the sum of cation mEq/L should equal the sum of anion mEq/L. If they diverge significantly, the reported ion concentrations may be averages from different tests or time periods and not representative of a single water sample. This is especially relevant when trying to replicate a specific historic city profile.

---

## 3. The Major Ions

### Cations (Positive Ions)

| Ion | Symbol | Recommended Range | Flavor Effect |
|-----|--------|-------------------|---------------|
| **Calcium** | Ca²⁺ | 50-150 ppm | Enhances enzyme activity, yeast health, clarity, protein coagulation. Primary hardness contributor. |
| **Magnesium** | Mg²⁺ | 10-30 ppm | Supports enzymes and yeast. Excess (>50 ppm) creates sour, bitter notes. |
| **Sodium** | Na⁺ | 0-40 ppm | Rounds malt character at low levels. Creates salty/mineral taste above 100 ppm. Flavor-positive—additions impact finished beer. |

### Anions (Negative Ions)

| Ion | Symbol | Recommended Range | Flavor Effect |
|-----|--------|-------------------|---------------|
| **Sulfate** | SO₄²⁻ | 50-350 ppm | Accentuates hop bitterness, creates dry/crisp finish. Higher = more assertive hops. |
| **Chloride** | Cl⁻ | 0-200 ppm | Emphasizes malt character, fullness, sweetness. Creates softer, rounder mouthfeel. |
| **Bicarbonate** | HCO₃⁻ | 0-250 ppm | Provides alkalinity (buffering capacity). Raises mash pH. |

### Deeper Notes on Key Ions (Palmer/Kaminski, Ch. 3 and 7)

**Calcium** -- "the friend of all brewers who brew with alkaline water" (Palmer/Kaminski). Beyond lowering mash pH:
- Protects and promotes enzyme activity
- Aids protein coagulation, trub formation, and yeast flocculation
- Promotes oxalate precipitation early in the process (preventing gushing in the package). Water should have at least 3x more calcium than oxalate in the malt.
- Too high a concentration (>250 ppm due to gypsum additions) can inhibit magnesium uptake by yeast and impair fermentation.
- Perceived as "minerally" above ~200 ppm, similar to bottled mineral water.
- Old brewer's rule: add 2/3 of mineral additions to the mash, 1/3 to the boil.

**Magnesium** -- Works at half the effectiveness of calcium for lowering mash pH (due to higher solubility of magnesium phosphates). A 10 Plato all-malt wort made with distilled water contains approximately 70 ppm Mg from the malt alone -- generally more than yeast requires (minimum 5 ppm). According to the EBC Manual of Good Practice, magnesium sulfate does not affect beer flavor below 7.1 mEq/L (~86 ppm Mg), but above that imparts "an unpleasant sour and bitter taste." Palmer/Kaminski co-author Colin Kaminski adds Epsom salt to dark beers like porter to achieve a minimum of 30 ppm Mg, believing it contributes to flavor.

**Sodium** -- According to the EBC Manual of Good Practice, when associated with chloride, sodium gives a salty taste at >150 ppm but improves mouthfeel and fullness in pale beers below that threshold. Ale beers are less affected by sodium chloride than lager beers. The combination of high sodium (>100 ppm) with high sulfate (>300 ppm) produces "a very harsh, sour/bitter minerally flavor." Softened water (ion exchange) replaces Ca and Mg with sodium, making it generally unsuitable for brewing.

**Zinc** -- Not a major ion but important as a yeast nutrient. Recommended in wort at 0.1-0.5 ppm. Above 0.5 ppm causes over-activity and off-flavors. Yeast are excellent scavengers of zinc, so residual zinc in finished beer is typically negligible.

### The Chloride-to-Sulfate Ratio

This ratio is one of the most powerful tools for shaping beer character:

| Ratio (Cl:SO₄) | Character | Best For |
|----------------|-----------|----------|
| 1:3 or higher sulfate | Dry, crisp, assertive hop bitterness | West Coast IPA, British Pale Ale |
| 1:1 balanced | Balanced, versatile | Amber ales, many styles |
| 2:1 chloride-forward | Fuller, maltier, softer | Stouts, malt-focused ales |
| 3:1 or higher chloride | Pillowy soft, round, "juicy" | NEIPA, Pastry Stout |

**Sean Lawson** (Lawson's Finest Liquids): "If we were talking about music, sulfates might lend a staccato note whereas chloride would have more legato tones."

---

## 4. Mash pH and Residual Alkalinity

### Target Mash pH: 5.2-5.6

This slightly acidic range:
- Optimizes enzyme activity (starch conversion)
- Improves yeast viability
- Inhibits bacterial growth
- Enhances hop extraction and utilization
- Promotes protein precipitation (clarity)
- Reduces chill haze

**Key insight**: The pH of your water in the liquor tank matters less than what happens when water meets grain. The mineral content (hardness) and grain bill combine to determine mash pH.

### How Mash pH Forms

During mashing, calcium and magnesium react with phosphatic compounds (phytins) in the malt to produce acids. This reaction:
1. Acidifies the mash
2. Reduces water hardness
3. Reduces buffering capacity

The balance of this reaction is called **Residual Alkalinity (RA)** -- a key factor in maintaining proper mash pH.

### The Phosphate Buffering System (Palmer/Kaminski, Ch. 4-5)

The mash contains two critical buffer systems:

1. **The carbonate/bicarbonate system** (from the water): Alkalinity via the equilibrium of CO2, HCO3-, and CO3-2.
2. **The phosphate system** (from the malt): Malted barley contains approximately 1% phosphate by weight, primarily bound as **phytin** (a mixed potassium and magnesium salt of phytic acid).

During mashing, phytin is hydrolyzed and the phosphate ions (mostly H2PO4-, but also H3PO4, HPO4-2, and PO4-3) become available to react with calcium. The precipitate formed is primarily **hydroxyl apatite**: Ca10(PO4)6(OH)2.

**The summarized apatite reaction**:

```
10Ca+2 + 12HCO3- + 6H2PO4- + 2H2O --> Ca10(PO4)6(OH)2 + 12CO2 + 12H2O + 2H+1
```

In plain terms: malt phosphate reacts with dissolved calcium to precipitate calcium phosphate, releasing protons (H+) that react with dissolved carbonates to produce water and CO2. This reduces alkalinity and lowers pH.

**Why phosphate is rarely limiting**: At roughly 1% of malt by weight and a typical grist ratio of 4 L/kg, the mash contains approximately 2,000 ppm of phosphate -- versus a typical calcium content of less than 100 ppm. The calcium in the water is almost always the limiting factor, not the phosphate.

**The role of melanoidins**: Specialty malts contribute a second source of acidity via melanoidins and organic acids created during Maillard reactions in kilning and roasting. Palmer/Kaminski note that there are effectively two categories of specialty malt acidity:
- **Kilned/caramel malts** (not roasted): Acidity increases with color up to approximately 325-355 F / 165-180 C processing temperature.
- **Roasted malts** (chocolate, black): Acidity actually *decreases* from the kilned/caramel peak. The high-molecular-weight Maillard compounds formed at higher temperatures consume or transform the lower-MW acidic compounds.

This means a high-color caramel malt (e.g., Crystal 120) can be more acidic than a lower-color roasted malt (e.g., chocolate malt), despite the roasted malt being darker.

### The Kolbach Residual Alkalinity Formula

In 1953, German brewing scientist Paul Kolbach conducted experiments on base malt worts and determined:
- **3.5 equivalents of calcium** react with malt phosphate to neutralize 1 equivalent of water alkalinity.
- **7 equivalents of magnesium** are needed to neutralize 1 equivalent of alkalinity (magnesium is half as effective due to the higher solubility of magnesium phosphate/hydroxide).

The Kolbach formula for residual alkalinity:

```
RA (mEq/L) = Alkalinity (mEq/L) - [(Ca mEq/L) / 3.5 + (Mg mEq/L) / 7]
```

Or in more familiar units:

```
RA (ppm as CaCO3) = Alkalinity (ppm as CaCO3) - [(Ca ppm) / 1.4 + (Mg ppm) / 1.7]
```

- **Positive RA**: Mash pH will be higher than the distilled water mash pH ("normal" pH of about 5.7-5.8).
- **Negative RA**: Mash pH will be lower than distilled water mash pH.

### Refinements to RA: Grist Ratio and Crush Size (Troester, via Palmer/Kaminski)

Kai Troester's research, cited extensively by Palmer/Kaminski, validated Kolbach's work but identified two additional factors:

**1. Grist ratio (water-to-grain)** affects the buffering capacity of the mash:

| Grist Ratio (L/kg) | Pilsner Malt Buffer Capacity (mEq RA per pH per L) | Munich Malt Buffer Capacity |
|---------------------|-----------------------------------------------------|----------------------------|
| 2 (0.96 qt/lb) | 23.8 | 28.6 |
| 3 (1.44 qt/lb) | 17.2 | 20.4 |
| 4 (1.92 qt/lb) | 15.2 | 15.2 |
| 5 (2.40 qt/lb) | 12.5 | 13.0 |

A thicker mash (lower ratio) has more buffering capacity, meaning more mEq of acid or base is needed to shift the pH by 0.1 unit.

**2. Degree of crush** also affects buffering capacity:

| Mill Gap (mm) | Pilsner Malt (mEq RA per pH per L) | Munich Malt |
|---------------|-------------------------------------|-------------|
| Pulverized | 15.8 | 17.8 |
| 0.5 (0.020") | 13.4 | 14.8 |
| 0.8 (0.032") | 12.2 | 14.8 |
| 1.2 (0.047") | 10.6 | 12.0 |

A finer crush exposes more phosphate for reaction, increasing buffering capacity. This effect diminishes with longer mash times as the grist becomes fully hydrated.

**Practical takeaway**: Kolbach's original coefficient (~12 mEq/(pH*L)) corresponds to a grist ratio near 5 L/kg. A modern typical value at 3 L/kg with a coarse grind is approximately 15 mEq/(pH*L).

### RA and Grain Color

| Grain Bill | RA Needed | Why |
|------------|-----------|-----|
| **Pale beers** | Low RA | Base malts provide minimal acidity; low RA lets pH settle in target range |
| **Dark beers** | Higher RA | Roasted malts are acidic; need alkalinity buffer to prevent excessively low pH |

**Brungard**: "As the acid content of the mash's grain bill increases, the mashing water RA must also rise proportionally to maintain the mash pH."

### Effects of Incorrect Mash pH (Palmer/Kaminski)

**Mash pH too low** (below 5.0, common with dark malts in low-RA water):
- One-dimensional grainy/roast flavor
- Impaired beta amylase activity (optimal range: 5.0-6.0)
- Increased wort fermentability but decreased body
- Low wort pH carries into the kettle, potentially reducing hop utilization and hop expression

**Mash pH too high** (above 5.8, common with pale malts in high-RA water):
- Increased tannin and silicate extraction from husks
- Harsh, astringent hop bitterness
- Beta amylase impairment
- Dull malt character; one-dimensional flavor
- Higher wort pH allows better alpha acid isomerization but creates a rougher, harsher bitterness -- brewers describe it as tasting "as if brewed with a different, higher-alpha hop variety"

### pH Measurement Notes (Palmer/Kaminski)

The pH of wort at mash temperature (~65 C / 150 F) is approximately **0.3 units lower** than the same wort cooled to room temperature (~20 C / 68 F). The standard for reporting and comparison is always room temperature.

The temperature correction can be approximated:

```
pH (room temp) = pH (mash) + 0.0055 * (T_mash - T_room) [in degrees Celsius]
```

Modern pH meters with ATC (automatic temperature compensation) correct for the **electrochemical response** of the probe, but they do **not** correct for the actual change in chemical activity of the wort with temperature. Always cool a sample before measuring, or apply the correction above.

---

## 5. Classic Water Profiles

Historic brewing cities developed styles that maximized their local water. Modern brewers replicate these profiles to brew authentic styles.

### Historic City Profiles (ppm)

| City | Ca | Mg | Na | SO₄ | Cl | HCO₃ | Best For |
|------|----|----|----|----|----|----|----------|
| **Burton-on-Trent** | 275 | 40 | 25 | 610 | 35 | 260 | English Pale Ale, IPA |
| **Pilsen** | 7 | 3 | 2 | 5 | 5 | 15 | Bohemian Pilsner |
| **Dublin** | 120 | 4 | 12 | 55 | 19 | 315 | Dry Irish Stout |
| **Munich** | 77 | 18 | 2 | 10 | 2 | 295 | Dunkel, Bock |
| **London** | 70 | 6 | 15 | 40 | 38 | 166 | Porter, Brown Ale |
| **Vienna** | 75 | 15 | 10 | 60 | 15 | 225 | Vienna Lager |
| **Dortmund** | 225 | 40 | 60 | 120 | 60 | 220 | Dortmunder Export |

*Source: Bru'n Water*

### Burton-on-Trent (English Pale Ales)

"The suitability of Burton water for brewing lies in its extreme hardness, particularly in terms of calcium and magnesium sulfates. These so-called gypseous waters promote protein coagulation during boiling, allow high hop-rate usage, and promote yeast growth; the result being the clear, sparkling ale for which Burton became famous." — Ian Hornsey, *Oxford Companion to Beer*

**Key characteristics**:
- Extremely high sulfate (610 ppm) creates assertive, clean hop bitterness
- High calcium promotes clarity and yeast health
- Low sodium keeps hop character clean

**Caution**: The Burton profile represents a highly mineralized aquifer that fluctuates throughout the year. Brewing at full Burton concentrations may produce sulfur notes.

### Pilsen (Bohemian Pilsner)

"Recreating a pilsner with vastly different water is one of the greatest challenges a brewer can undertake." — Palmer & Kaminsky

**Key characteristics**:
- Extremely soft water (nearly mineral-free)
- Very low alkalinity allows base malts to hit proper pH
- Absence of sulfate creates "mellow hop bitterness that does not overpower the soft maltiness"
- Results in "soft rich flavor of fresh bread"

### Dublin (Dry Irish Stout)

"Dublin has the highest bicarbonate concentration of the cities of the British Isles, and Ireland embraces it with the darkest, maltiest beer in the world." — John Palmer

**Key characteristics**:
- High bicarbonate buffers acidity from roasted malts
- Low sulfate creates unobtrusive hop bitterness
- Allows chocolate and coffee notes to shine

**Note**: Guinness at St James Gate historically drew from the Wicklow Mountains (essentially rainwater), which is why dry Irish stout has an "acidic bite"—the roasty malts become richer and fuller without alkalinity buffering.

---

## 6. Modern Style Profiles

### New England IPA (Hazy/Juicy IPA)

The NEIPA revolutionized water chemistry thinking by inverting traditional IPA ratios.

**Eric Thomas** (formerly Trillium, now Sixpoint): "When the NEIPA came out and everyone began exploring higher chloride to sulfate ratios, that's when it really drove home the impact on hop expression, softness, mouthfeel and overall textural experience."

**Recommended profile**:
- Chloride: 150-300 ppm (some go higher)
- Sulfate: 50-100 ppm
- Chloride:Sulfate ratio: 2:1 to 4:1
- Calcium: 50-100 ppm

**Effect**: "Pillowy softness and subtle sweetness... accentuates the juicy qualities of the style."

### West Coast IPA

Traditional approach emphasizing hop bitterness and dryness.

**Recommended profile**:
- Sulfate: 150-300 ppm
- Chloride: 50-75 ppm
- Sulfate:Chloride ratio: 2:1 to 3:1
- Calcium: 75-150 ppm

**Effect**: Assertive, clean hop bitterness; dry, crisp finish

### Pastry Stout / Imperial Stout

**Wayne Wambles** (Cigar City): "Increased sulfate levels are not a good thing for bigger, sweeter, malt forward stouts. It elevates the hop profile and can throw the malt balance off."

**Recommended profile**:
- Chloride: 150-200 ppm
- Sulfate: <100 ppm
- Chloride:Sulfate ratio: 2:1 or higher

---

## 6.5 Sparge Water Chemistry (Palmer/Kaminski, Ch. 6)

Sparge water is one of the most overlooked areas of brewing water chemistry. Palmer and Kaminski dedicate significant attention to the risks of uncontrolled sparge water pH.

### The Problem: pH Rise During Sparging

At the beginning of the sparge, the mash pH should be at target and the buffering conditions within the mash at full strength. As sparge water rinses the grain bed:
1. Sugars and buffer compounds are progressively rinsed away
2. The pH of the grain bed shifts toward the pH of the incoming sparge water
3. If the sparge water is alkaline, the grain bed pH rises

**Critical threshold**: As the grain bed pH approaches **5.8**, extraction of **tannins, silicates, and ash** from malt husks increases dramatically. These compounds can ruin the taste of an otherwise well-brewed beer.

### Sierra Nevada Experiment (Palmer/Kaminski, Table 13)

Jim Mellem of Sierra Nevada presented data comparing three conditions for pale ale on a 10-barrel pilot system:

| Condition | Mash pH | Last Runnings pH | Final Wort pH | Sensory Result |
|-----------|---------|-----------------|---------------|----------------|
| Standard (water acidified to 5.7) | 5.30 | 5.56 | 5.17 | Superior: less astringency, less harshness |
| Standard salts, no acidification | 5.49 | **5.91** | 5.37 | Inferior: statistically significant increase in astringency/harshness |
| 2x CaCl2, no acidification | 5.38 | **5.83** | 5.31 | Inferior: perceivable harshness |

38 trained panelists found statistically significant differences (alpha=0.05) in astringency, harshness, and acceptability. The standard brew with acidified water was rated superior in each attribute.

### Sparge Water Best Practices

1. **Acidify sparge water** to a pH in the mash target range (5.2-5.6). This effectively prevents the grain bed pH from rising above 5.8 during lautering. Phosphoric or lactic acid are the most common choices.

2. **Stop sparging** if the grain bed pH exceeds 5.8 or the specific gravity of the runnings falls below **1.008** (3 Plato). Top up the kettle with hot liquor alone. The small drop in efficiency is far preferable to extracting harsh tannins.

3. **Never add alkalinity to sparge water**. Palmer/Kaminski are explicit: "The alkalinity of sparge water always needs to be as low as possible to minimize or prevent pH rise in the grain bed during lautering."

4. **Maintain sufficient calcium** in the brewing water. One of Palmer/Kaminski's practical examples describes a wheat beer where calcium was reduced to 24 ppm -- the final runnings pH spiked, and the finished beer had "a distinct dry, harsh, and almost ashy aftertaste." Increasing calcium to 36 ppm on the next batch prevented the pH rise.

### Mash vs. Sparge vs. Kettle: Where to Add Salts and Acid

| Addition Target | What to Add | Why |
|-----------------|-------------|-----|
| **Mash (strike water)** | Calcium salts (gypsum, CaCl2); acid as needed for pH | Calcium reacts with malt phosphate to lower pH; ensures enzyme activity; 2/3 of total mineral additions (old brewer's rule) |
| **Sparge water** | Acid only (phosphoric or lactic); no alkalinity additions | Prevent pH rise during lautering; never add bicarbonate or carbonate |
| **Kettle** | Remaining 1/3 of calcium salts; flavor salts (NaCl, etc.) | Ensures sufficient calcium for protein coagulation, trub formation, oxalate precipitation; flavor ion adjustments |

---

## 7. Water Treatment Methods

### Removing Chlorine/Chloramine

Municipal water contains disinfectants that can form **chlorophenols** (soapy, medicinal, band-aid off-flavors) at very low concentrations. Tap water typically has 100× the chlorine needed to produce these faults.

| Method | Effectiveness | Notes |
|--------|---------------|-------|
| **Campden tablets** (metabisulfite) | Excellent | ~500 mg per 10 gallons; instant; removes chloramine too |
| **Activated carbon filter** | Excellent | Whole-house or inline filter |
| **Boiling** | Good for chlorine | Does NOT remove chloramine |
| **Letting water sit** | Marginal | Only works for chlorine, takes 24+ hours |
| **Ascorbic acid** | Good | Vitamin C; instant |

**Brungard**: "Completely removing disinfectants from municipal water eliminates a huge detractor in beer quality right there."

### Reducing Hardness/Alkalinity

| Method | What It Does | Notes |
|--------|--------------|-------|
| **RO or distilled water dilution** | Reduces all minerals proportionally | Most common approach; blend to target |
| **Boiling** | Precipitates calcium carbonate | Reduces temporary hardness and alkalinity; raise temp causes bicarbonate to precipitate |
| **Acid addition** | Neutralizes alkalinity | Lactic, phosphoric, or acidulated malt |
| **Lime softening** | Ca(OH)2 raises pH to precipitate CaCO3 | Can achieve lower alkalinity than boiling; also removes iron, manganese, silica |

### Detailed Decarbonation Methods (Palmer/Kaminski, Ch. 6)

**Boiling**: The rise in temperature reduces CO2 solubility. As CO2 evolves, the equilibrium shifts, converting bicarbonate to carbonate. Calcium carbonate precipitates. The reaction:

```
Ca+2 + 2HCO3- <--> CaCO3 (precipitate) + CO2 (gas) + H2O
```

Palmer/Kaminski note that boiling reduces alkalinity to approximately **1 mEq/L** (50 ppm as CaCO3) of each calcium and bicarbonate remaining. Historical data (Latham, 1884) shows that vigorous boiling for 30 minutes reduces hardness from 192 to 37 ppm as CaCO3. "Sharp boiling for not less than 20 minutes is requisite." The water must then be decanted off the white precipitate.

**Residual calcium after boiling** can be estimated:

```
[Ca]final = [Ca]initial - (([HCO3]initial - [HCO3]final) / 3.05)
```

Where all concentrations are in ppm. Use 61 ppm for ideal final HCO3 or 80 ppm for a more conservative estimate.

**Boiling works best** when total hardness as CaCO3 is greater than total alkalinity as CaCO3 (ample calcium to fuel the precipitation). Adding CaSO4 or CaCl2 before boiling increases the calcium available and enhances decarbonation.

**Lime softening** (Ca(OH)2): First patented in 1841 by Dr. Thomas Clark. Slaked lime adds calcium and raises pH to precipitate CaCO3 and Mg(OH)2. Can achieve alkalinity as low as 25 ppm as CaCO3 (lower than boiling). The key reactions:

```
Ca(OH)2 + CO2 <--> CaCO3 + H2O
Ca(OH)2 + Ca(HCO3)2 <--> 2CaCO3 + 2H2O
2Ca(OH)2 + Mg(HCO3)2 <--> Mg(OH)2 + 2CaCO3 + 2H2O
```

**Home-scale lime softening** (deLange method, via Palmer/Kaminski):
1. Add 1 tsp chalk per 5 gallons as nucleation sites
2. Calculate lime needed: multiply temporary hardness by 0.74 to get mg/L required, then scale to volume
3. Increase the calculated amount by 20-30%
4. Add lime slurry in decreasing increments while stirring; target pH 9.5-10
5. Monitor pH as it drops back from precipitation
6. When rate of pH decline slows, stop adding lime; let precipitate settle
7. Decant and measure hardness and alkalinity

### Acid Types for Alkalinity Reduction (Palmer/Kaminski, Ch. 6)

Each acid replaces alkalinity equivalents with its own anion -- a factor in recipe formulation:

| Acid | Type | Equivalents/Mole | Anion Contributed | Flavor Notes |
|------|------|-------------------|-------------------|--------------|
| **Lactic** (88%) | Organic, monoprotic | 1 | 89 ppm lactate per mEq | Smooth sourness; flavor threshold ~400 ppm in beer. Permitted under Reinheitsgebot. |
| **Phosphoric** (85%) | Weak, ~monoprotic at mash pH | ~1-1.3 | ~96 ppm H2PO4- per mEq | Minimal flavor impact; malt already rich in phosphate. Risk of calcium precipitation as apatite. |
| **Hydrochloric** (10%) | Strong, monoprotic | 1 | 35.4 ppm Cl- per mEq | Boosts chloride without adding calcium. |
| **Sulfuric** (10%) | Strong, diprotic | 2 | 48 ppm SO4-2 per mEq | Boosts sulfate without adding calcium. Handle with extreme caution. |

**Calculating acid additions**: Convert alkalinity from ppm as CaCO3 to mEq/L by dividing by 50. The difference between current and target mEq/L equals the mEq of acid needed per liter. Example: reducing alkalinity from 125 to 75 ppm as CaCO3 requires (125-75)/50 = 1.0 mEq/L of acid.

**Phosphoric acid caution**: When acidifying water with phosphoric acid before the mash, calcium can precipitate as apatite. Ironically, this is *more* likely when acidifying only slightly (to pH 6.0) than when acidifying more aggressively (to pH 5.5), because calcium phosphate is less saturated at lower pH. Palmer/Kaminski recommend adding calcium salts first, then acidifying, to ensure stable calcium levels.

### Increasing Hardness/Minerals

| Addition | Effect per gram/gallon | Notes |
|----------|------------------------|-------|
| **Gypsum** (CaSO₄) | +62 ppm Ca, +148 ppm SO₄ | Lowers pH; hop emphasis |
| **Calcium chloride** (CaCl₂) | +72 ppm Ca, +128 ppm Cl | Lowers pH; malt emphasis |
| **Epsom salt** (MgSO₄) | +26 ppm Mg, +103 ppm SO₄ | Use sparingly |
| **Baking soda** (NaHCO₃) | +75 ppm Na, +192 ppm HCO₃ | Raises alkalinity; adds sodium |
| **Chalk** (CaCO₃) | +106 ppm Ca, +158 ppm HCO₃ | Dissolves poorly; use slaked lime instead |
| **Pickling lime** (Ca(OH)₂) | Raises pH, adds calcium | For raising RA in dark beers |
| **Non-iodized salt** (NaCl) | +104 ppm Na, +160 ppm Cl | Use sparingly; for Gose, etc. |

### Detailed Ion Contributions by Salt (Palmer/Kaminski, Table 17)

The following table provides precise contributions at 1 gram per liter and 1 gram per gallon, based on molecular weight calculations including waters of hydration:

| Salt (Formula) | Per gram/liter: Cation | Per gram/liter: Anion | Per gram/gallon: Cation | Per gram/gallon: Anion | Notes |
|----------------|------------------------|------------------------|--------------------------|-------------------------|-------|
| **Gypsum** (CaSO4-2H2O, mw=172.2) | 232.8 ppm Ca | 557.7 ppm SO4 | 61.5 ppm Ca | 147.4 ppm SO4 | Saturation ~2 g/L. Stir vigorously. |
| **Calcium chloride** (CaCl2-2H2O, mw=147.0) | 272.6 ppm Ca | 482.3 ppm Cl | 72.0 ppm Ca | 127.4 ppm Cl | Absorbs moisture; keep sealed. Food-grade may vary in purity (75-80% CaCl2-2H2O). |
| **Epsom salt** (MgSO4-7H2O, mw=246.5) | 98.6 ppm Mg | 389.6 ppm SO4 | 26.0 ppm Mg | 102.9 ppm SO4 | Saturation ~255 g/L. |
| **Baking soda** (NaHCO3, mw=84) | 273.7 ppm Na | 710.5 ppm HCO3 | 72.3 ppm Na | 188 ppm HCO3 | Dissolves readily. 11.8 mEq/L alkalinity at 99% yield. |
| **Calcium hydroxide** (Ca(OH)2, mw=74.1) | 541 ppm Ca | 459 ppm OH- | 143 ppm Ca | 121 ppm OH- | Dissolves readily. RA change = 19.3 mEq/g per L. |
| **Sodium hydroxide** (NaOH, mw=40) | 575 ppm Na | 425 ppm OH- | 152 ppm Na | 112.3 ppm OH- | HAZARDOUS. Dissolves readily. 25 mEq/L alkalinity. |

### How to Calculate Salt Additions from Scratch (Palmer/Kaminski, Appendix C)

The procedure for calculating ion contributions from any salt:

1. **Divide** the weight of salt (e.g., 1 gram) by its molecular weight (including waters of hydration) to get the mole fraction.
2. **Calculate** the weight fraction of each ion in the compound (ion atomic weight / total molecular weight).
3. **Multiply** the weight fraction by the addition weight to get milligrams of each ion.
4. **Divide** by the volume in liters to get ppm (mg/L). For gallons, divide by 3.785.

**Example** (Palmer/Kaminski): 1 gram CaCl2-2H2O in 1 gallon:
- Molecular weight: 40 + (2 x 35.5) + 2 x (2 + 16) = 147 g/mol
- Ca fraction: 40/147 = 0.272 --> 272 mg Ca per gram
- Cl fraction: 71/147 = 0.483 --> 483 mg Cl per gram
- Per gallon: 272/3.785 = **71.8 ppm Ca**, 483/3.785 = **127.6 ppm Cl**

### Swapping Sulfate and Chloride Salts (Palmer/Kaminski, Appendix C)

To change the sulfate-to-chloride ratio without changing total calcium, use simultaneous equations:

Given: target calcium (T_Ca), desired SO4:Cl ratio of 1:1

```
Equation 1 (equal anions): 147.4 * X = 127.4 * Y
Equation 2 (calcium target): 61.5 * X + 72.0 * Y = T_Ca
```

Where X = grams/gallon of gypsum, Y = grams/gallon of CaCl2. Solve for X and Y.

**Example**: To achieve 65 ppm Ca with a 1:1 SO4:Cl ratio:
- Y = 1.16X (from equation 1)
- 61.5X + 83.5X = 65, so X = 0.448 g/gal gypsum, Y = 0.520 g/gal CaCl2
- Result: 65 ppm Ca, 66 ppm SO4, 66 ppm Cl

### Raising RA for Dark Beers

**Palmer & Kaminski caution**: "It is difficult to add more alkalinity to a soft water without adding significant hardness or sodium as well. It is often a case of two steps forward, one step back."

Options:
1. **Baking soda**: Raises alkalinity but adds flavor-active sodium (~72 ppm Na per gram/gallon). Keep sodium below 100 ppm, especially if sulfate exceeds 300 ppm (metallic taste).
2. **Pickling lime** (Ca(OH)2): Raises pH and adds calcium. Has a high delta-RA of 19.3 mEq/g per L. Dissolves readily.
3. **Reserve roasted grains**: Add dark malts late in mash (or at vorlauf) to reduce acid contribution.

### Why Chalk Does Not Work (Palmer/Kaminski, Ch. 6)

Palmer/Kaminski provide an extended analysis of why adding chalk (CaCO3) to the mash is largely ineffective:

**Solubility problem**: Chalk is practically insoluble in water -- only about 0.05 g/L at standard temperature and pressure, or roughly 2 grams in 10 gallons. It can be dissolved by bubbling CO2 through the water under pressure, but this is impractical for most brewers.

**The apatite trap**: When undissolved chalk is added to the mash, the calcium from the chalk immediately reacts with the abundant malt phosphate to precipitate as hydroxyl apatite. This reaction consumes approximately 70% of the alkalinity that the chalk was supposed to contribute:

```
10CaCO3 + 6H2PO4- + 2H2O --> Ca10(PO4)6(OH)2 + 10HCO3- + 4H+1
```

Experiments by deLange (cited in Palmer/Kaminski) showed that suspended chalk in a phosphate solution raised pH only about 1/3 as effectively as predicted. The resulting precipitate was "fluffier" than chalk and confirmed to be apatite.

**Practical rate**: pH changes from chalk additions occur very slowly -- approximately 15-30 minutes for a 0.1 pH change in the range of 4.6-5.5, and 30-60+ minutes for the same change above 5.5. It could take 3 hours to raise pH from 4.9 to 5.4.

**Better alternatives for raising RA**:
- Sodium bicarbonate (NaHCO3): soluble and effective, but watch sodium
- Calcium hydroxide (Ca(OH)2): soluble and effective, adds calcium
- Sodium hydroxide (NaOH): effective but hazardous; for experienced brewers only
- Sodium carbonate (Na2CO3): unlike chalk, does not experience the apatite trap because sodium does not react with malt phosphate

---

## 7.5 The Carbonate System in Depth (Palmer/Kaminski, Ch. 4)

Understanding the carbonate equilibrium is essential to understanding why alkalinity behaves the way it does.

### The Three Carbonate Species

Dissolved carbonate exists in three forms depending on pH:

1. **Aqueous CO2 / Carbonic acid (H2CO3*)**: Dominates below pH 4.3. This is actually mostly dissolved CO2 -- only about 0.17% actually forms carbonic acid.
2. **Bicarbonate (HCO3-)**: Dominates between pH 6.3 and 10.3, peaking at about pH 8.3. This is the predominant form in potable water.
3. **Carbonate (CO3-2)**: Dominates above pH 10.3.

The equilibrium is governed by dissociation constants (at 20 C / 68 F):

```
CO2 + H2O <--> H2CO3*     pKH = 1.41
H2CO3* <--> HCO3- + H+    pK1 = 6.38
HCO3- <--> CO3-2 + H+     pK2 = 10.38
CaCO3 <--> Ca+2 + CO3-2   pKs = 8.38
```

Below pH 4.3, the carbonate has entirely converted to aqueous CO2 and carbonic acid -- this region is called "free mineral acidity." In the mash pH range (5.2-5.6), the carbonate system is mostly aqueous CO2 with a lesser proportion of bicarbonate.

### How Alkaline Water Forms in Nature

The key is the partial pressure of CO2 underground, which can reach 0.03 to 0.05 atm (compared to 0.0003-0.0005 atm at the surface). This high CO2 pressure creates acidic groundwater that dissolves limestone:

```
CO2 + H2O + CaCO3 --> Ca+2 + 2HCO3-
```

When groundwater surfaces, the excess CO2 slowly releases to the atmosphere. The resulting supersaturation explains why calcium carbonate scale gradually builds on faucets and shower heads -- the equilibrium is slowly restoring itself.

### Solubility of Calcium Carbonate

- In pure water (no dissolved CO2): only ~14 ppm
- In contact with atmospheric CO2: ~50 ppm (1 mEq/L)
- With higher dissolved CO2: up to ~75 ppm
- In the presence of other salts (NaCl, MgSO4): slightly higher, due to ionic shielding

**Temperature effect**: Both CaCO3 and CaSO4 decrease in solubility with rising temperature, which is why scaling occurs on heating elements and hot water pipes.

---

## 8. Chloride Cautions

While high chloride creates desirable softness in NEIPAs and stouts, **Water: A Comprehensive Guide for Brewers** warns:

| Chloride Level | Concern |
|----------------|---------|
| >100 ppm | Can corrode stainless steel brewing equipment |
| >200 ppm | General upper limit for most styles |
| >300 ppm | May adversely impact clarification, body, colloidal stability, yeast health |
| >400 ppm | Negative flavor effects; "minerally" taste |

---

## 8.5 Sulfate-to-Chloride Ratio: Deeper Guidelines (Palmer/Kaminski, Ch. 7)

Palmer and Kaminski (specifically Colin Kaminski's decade of commercial brewing experience) provide these refined guidelines:

1. **The useful range of the sulfate-to-chloride ratio is 0.5 to 9**, predominantly for ales. Pale and light lagers with fine noble hop aroma are more sensitive to sulfate; levels below 100 ppm SO4 are generally recommended for those styles.

2. **The ratio is not magic** -- "a ratio of 30:30 ppm is not equal to 300:300 ppm, despite published references that suggest it." A minimum concentration is needed before the effect is perceptible.

3. **Minimum effective levels**: Approximately 50 ppm chloride and 50 ppm sulfate before either has noticeable flavor impact.

4. **Recommended maximums**: Chloride: 200 ppm in mashing water. Sulfate: 500 ppm (some great beers have been made above 800 ppm, but many people are sensitive to high sulfate -- it can cause gastrointestinal distress).

5. **High levels of both simultaneously** taste minerally and harsh. Do not try to maximize both in the same beer.

6. **Experiment in the glass**: Palmer/Kaminski recommend dissolving CaCl2 and CaSO4 in separate glasses of warm water, then using a straw or eyedropper to dose individual glasses of beer with varying amounts. This gives firsthand experience of the ratio's effect without brewing a full batch.

---

## 9. Building Water from RO/Distilled

Starting with RO or distilled water gives a "blank slate" for precise profile building.

### RO/Distilled Water pH Note (Palmer/Kaminski)

When RO or distilled water is left exposed to air, CO2 dissolves from the atmosphere and the pH gradually drops toward 5 -- just as it does with rainwater. This is normal and does not represent a problem for brewing. The water has essentially zero buffering capacity, so the pH reading is largely meaningless for predicting mash behavior.

If you are building your water from RO and not adding alkalinity, acidification for sparging is generally not needed.

### Basic Process

1. **Get water report** from your municipal source (or test)
2. **Choose target profile** based on style
3. **Calculate mineral additions** using software (Bru'n Water, Brewfather)
4. **Add salts** to strike water before mashing (add salts before acid -- Palmer/Kaminski recommend this order to ensure stable calcium levels)
5. **Check mash pH** at 15 minutes; adjust if needed

### Example: Building NEIPA Water (5 gallons)

Target: Ca 75, Mg 5, Na 10, SO₄ 50, Cl 150

Starting with RO water:
- Calcium chloride: 4.5 g → +65 ppm Ca, +115 ppm Cl
- Gypsum: 1.0 g → +12 ppm Ca, +30 ppm SO₄
- Epsom salt: 0.5 g → +5 ppm Mg, +20 ppm SO₄
- Table salt: 0.5 g → +10 ppm Na, +35 ppm Cl

Result: Ca ~77, Mg 5, Na 10, SO₄ 50, Cl 150 ✓

---

## 10. Tools and Testing

### Water Reports

- **Municipal water**: Request from your water utility (often available online)
- **Well water**: Send sample to Ward Labs or similar
- **Reports typically include**: pH, total hardness, alkalinity, Ca, Mg, Na, Cl, SO₄, and more

### Software Tools

| Tool | Type | Cost | Notes |
|------|------|------|-------|
| **Bru'n Water** | Spreadsheet | Free | Industry standard; created by Martin Brungard |
| **Brewfather** | Web/app | Free tier / $2.50/mo | Full brewing software with water calculator |
| **Brewer's Friend** | Web | Free tier / $3/mo | Includes water calculator |
| **EZ Water Calculator** | Spreadsheet | Free | Simpler alternative |

### Testing Equipment

| Equipment | Purpose | Cost |
|-----------|---------|------|
| **pH meter** (with ATC) | Measure mash pH | $50-150 |
| **pH test strips** | Rough mash pH check | $10-20 |
| **LaMotte water test kit** | Full mineral analysis | ~$200/year |
| **Jewelry scale** (0.01g) | Precise salt weighing | $15-30 |

**Tip**: pH meters require calibration and proper storage (electrode in storage solution). Temperature affects pH readings—use automatic temperature compensation (ATC) or correct manually.

---

## 10.5 Brewery Process Water (Palmer/Kaminski, Ch. 8-9)

Palmer and Kaminski note that brewing is water-intensive, using 5-10 volumes of water per volume of beer produced. Water requirements differ by use:

### Dilution Water (High-Gravity Brewing)

Many production breweries practice high-gravity brewing and dilute before packaging. Post-fermentation dilution water has the strictest requirements:
- Must be **disinfected** (risk of spoilage in the package, even if pasteurized)
- Must be **deaerated** (oxygen causes premature staling)
- Calcium content must be **lower than the concentrated beer's calcium** -- otherwise calcium oxalate crystals precipitate in the package, acting as bubble nucleation sites and causing gushing

### Cleaning Water

The term "hard water" originally comes from the cleaning industry -- "hard" means it is hard to raise a lather because calcium and magnesium bind the active sites in soaps. For cleaning applications, water is typically softened by ion exchange. Brewery cleaning water requirements differ from brewing water requirements.

### Boiler Feedwater

Poor management of boiler water can cause carbonate scale, reducing energy efficiency and equipment life. Boiler water treatment is essential for maintaining steam-generating systems.

### Sierra Nevada's Approach

Palmer and Kaminski cite Sierra Nevada as an exemplary approach: they taste- and smell-test water daily using a minimum of four people at six different points in the brewing process -- incoming water, post-dechlorination, post-carbon filtration, cold liquor tank, hot liquor tank, and deaerated water tank. Other process waters (bottling jetter, rinse) are tested weekly.

---

## 11. Climate and Seasonal Variation

Water sources change throughout the year and with climate conditions:

- **Snowmelt/rainfall**: Adds sediment, may dilute or change mineral content
- **Drought**: Concentrates minerals; may force utility to switch sources
- **Source switching**: Utilities blend from multiple sources based on availability

**Mitch Steele** (formerly Stone Brewing): "We would see variations of 100-150 ppm hardness to over 400 ppm" when California drought forced increased use of Colorado River water.

### Best Practices

1. **Build relationship with water utility**: Ask to be notified of source changes
2. **Test periodically**: Especially after major weather events
3. **Consider RO**: Provides consistency regardless of source changes
4. **Document everything**: Track water source dates and mineral content with batches

---

## 12. Quick Reference Tables

### Style-Based Water Profiles

| Style | Ca | SO₄ | Cl | SO₄:Cl | RA |
|-------|----|----|----|----|-----|
| Bohemian Pilsner | 10 | 10 | 10 | 1:1 | Very low |
| German Lager | 50 | 50 | 50 | 1:1 | Low |
| American Lager | 50 | 50 | 50 | 1:1 | Low |
| English Bitter | 100 | 150 | 50 | 3:1 | Low |
| West Coast IPA | 100 | 200 | 75 | 2.5:1 | Low |
| NEIPA | 75 | 50 | 150 | 1:3 | Low |
| Amber/Red Ale | 75 | 75 | 100 | 1:1.3 | Low-moderate |
| Brown Ale | 75 | 50 | 100 | 1:2 | Moderate |
| Porter | 75 | 50 | 100 | 1:2 | Moderate |
| Dry Stout | 100 | 50 | 75 | 1:1.5 | Moderate-high |
| Sweet Stout | 75 | 50 | 150 | 1:3 | Moderate |

### Common Water Additions (per 5 gallons)

| Goal | Addition | Amount |
|------|----------|--------|
| +50 ppm sulfate | Gypsum | 1.7 g |
| +50 ppm chloride | Calcium chloride | 2.0 g |
| +50 ppm calcium | Gypsum | 4.0 g |
| +50 ppm calcium | Calcium chloride | 3.5 g |
| Lower mash pH 0.1 | Lactic acid (88%) | ~1 mL |
| Lower mash pH 0.1 | Phosphoric acid (10%) | ~2 mL |
| Remove chlorine | Campden tablet | ¼ tablet |

### Troubleshooting

| Problem | Likely Cause | Solution |
|---------|--------------|----------|
| Harsh, astringent bitterness | Mash pH too high (>5.8) | Add acid; check alkalinity |
| Dull, flat-tasting beer | High alkalinity, no acid addition | Lower RA; add acid to mash |
| Soapy/medicinal off-flavor | Chlorophenols from chlorine | Campden tablets; carbon filter |
| Thin, watery mouthfeel | Low chloride | Increase calcium chloride |
| Overly bitter, harsh | High sulfate; pH issue | Reduce sulfate; check mash pH |
| Salty taste | Sodium >100 ppm | Reduce sodium additions; dilute with RO |

---

## 13. Water Chemistry for Distilling

While brewing water chemistry focuses on mash pH and flavor ion balance, distilling has distinct requirements at each stage of production. Water is used in mashing, fermentation, and — most critically — proofing/dilution, where it can comprise **50–60% or more** of the final bottled spirit.

### Sources

- [Water | Distiller Magazine](https://distilling.com/distillermagazine/water/)
- [Mash Chemistry 101 | Distiller Magazine](https://distilling.com/distillermagazine/mash-chemistry-101/)
- [The Fuss Over Water | Distiller Magazine](https://distilling.com/distillermagazine/the-fuss-over-water/)
- [Water, Distilled | Artisan Spirit Magazine](https://www.artisanspiritmag.com/blog-posts/water-distilled-3)
- [Fine Tuning Water | Murphy and Son](https://www.murphyandson.co.uk/fine-tuning-water-tips-for-crafting-exceptional-spirits/)
- [Water: It's More Than Just H's and O's | Spirits & Distilling](https://www.spiritsanddistilling.com/water-it-s-more-than-just-hs-and-os)
- [How Water Affects Whiskey | Distiller](https://distiller.com/articles/water-affects-whiskey)
- [Glenora Distillery: Water in Whisky Production](https://www.glenoradistillery.com/our-blog/2024/3/22/water-in-whisky-production)
- [How Water Affects the Quality of Vodka | Nemiroff](https://nemiroff.vodka/en-uk/about-vodka-en-uk/how-water-affects-the-quality-of-vodka/)
- [What is Louching | Everglow Spirits](https://everglowspirits.com/what-is-louching-exploring-gins-cloudy-secret/)

### Key Differences from Brewing

| Stage | Brewing | Distilling |
|-------|---------|------------|
| **Mash water** | Detailed ion profiles for flavor | Primarily enzyme/yeast support; flavor compounds distill over |
| **Fermentation** | Moderate mineral needs | Similar to brewing |
| **Final product water** | N/A | Proofing water is 50–60%+ of bottled spirit; critical for clarity and mouthfeel |

The distillation process strips most minerals from the spirit, so mash water mineral content has less direct flavor impact than in brewing. However, minerals still affect enzyme activity and yeast health during mashing and fermentation.

### 13.1 Mash Water for Distilling

**Target mash pH: 5.2–5.8** (optimum 5.4) — identical to brewing.

Above pH 5.8, starch conversion slows significantly. Below pH 5.0, amylase enzymes stop working altogether.

#### Recommended Mash Water Parameters

| Parameter | Target | Notes |
|-----------|--------|-------|
| **pH** | 5.2–5.8 (5.4 optimum) | Adjust with lactic acid if too alkaline |
| **Calcium** | 40–70 ppm (up to 150 ppm) | Stabilizes α-amylase; supports yeast; >250 ppm may inhibit Mg uptake |
| **Magnesium** | ≤40 ppm | Critical for yeast health, fermentation speed, ethanol tolerance |
| **Alkalinity (as CaCO₃)** | ≤50 ppm (max 100 ppm) | Low alkalinity allows pH control |
| **Zinc** | ≤0.05 ppm | Essential for yeast reproduction and alcohol dehydrogenase |
| **Chlorine/Chloramine** | 0 ppm | Damages yeast; creates off-flavors; remove with carbon filter or metabisulfite |
| **Iron** | <0.3 ppm | Corrodes stainless; causes black, bitter spirits |
| **Nitrate** | <10 ppm | Converts to nitrite during fermentation, impairing yeast |
| **Geosmin** | <0.006 ppm | Earthy compound; impossible to remove post-production |

**pH adjustment**: Use lactic acid to lower pH. It "ensures that your yeast works efficiently, leading to a more predictable and clean fermentation process."

**Calcium chloride** can be added to adjust water hardness — calcium promotes yeast health and "enhances the body and mouthfeel of the spirit, making it smoother and more balanced."

#### Enzyme Activity in Distilling Mashes

For distilling, **β-amylase** (optimal at 64°C / 147°F) is prioritized over α-amylase because distillers want maximum fermentable sugar yield. Unlike brewers, distillers often skip boiling the wort to preserve secondary enzymes (limit dextrinase, amyloglucosidase) that continue converting starches during fermentation — boosting fermentability by up to 15%.

### 13.2 Regional Water Effects on Whiskey

Research by Dr. Craig Wilson (master blender, Diageo) demonstrated measurable sensory differences based on source water:

| Water Type | Spirit Character |
|------------|------------------|
| **Soft water** (Speyside) | Heavier spirits |
| **Hard water** (Islay, Highlands) | Lighter, sweeter spirits |
| **High organic matter, low minerals** | More esters (fruity flavors) |

**Kentucky limestone water**: The "bourbon's secret ingredient" claim has some basis. Limestone-filtered water deposits calcium and magnesium while naturally removing iron (which would otherwise cause black, bitter spirits). This makes it well-suited for mashing — but unsuitable for proofing.

### 13.3 Proofing and Dilution Water

Proofing water is the most critical water in distilling. It constitutes **50–60% or more** of the final bottled product at standard 40% ABV, directly affecting flavor, mouthfeel, and clarity.

#### Golden Rule

**Use RO or deionized water for proofing.** This is the industry standard for good reason:

- As little as **2 ppm calcium** can cause precipitation in the final product
- Calcium and sulfate cause cloudiness even at very low concentrations
- Hard water causes haze from mineral interactions
- β-sitosterol (from barrel aging) can interact with minerals to precipitate

#### Proofing Water Requirements

| Parameter | Target | Why |
|-----------|--------|-----|
| **TDS (Total Dissolved Solids)** | <10 ppm (ideally 0) | Prevents haze, precipitation, off-flavors |
| **Calcium** | <2 ppm | Causes precipitation |
| **Sulfate** | Near 0 | Causes haze |
| **pH** | Neutral to slightly alkaline | Affects perceived smoothness |

#### Treatment Methods

| Method | Use | Notes |
|--------|-----|-------|
| **Reverse Osmosis (RO)** | Proofing water | Industry gold standard; removes minerals, bacteria, additives; produces ~2–6 gal waste per 1 gal product |
| **Deionization** | Proofing water | Removes all minerals via ion-exchange resins; creates chemically pure water |
| **Activated Carbon** | Chlorine removal | Preserves natural minerals; ~32,000 sq ft surface area per gram; less effective at removing fluoride |

**RO membrane performance**: Manufacturers claim 98% salt rejection with new membranes, but 92–95% is more realistic. If your source water has 1000 ppm TDS, expect ~50 ppm TDS in the product water.

#### Dilution Process

Some distillers add water gradually, allowing the spirit to rest between additions. This prevents **saponification** — where water brings fats or oils out of suspension, giving the whiskey a soapy taste.

After dilution, many distillers allow the spirit to **rest** (days to weeks) so water and alcohol fully integrate, smoothing flavor and enhancing mouthfeel.

### 13.4 Vodka: Where Water Matters Most

Vodka is approximately **60% water** by volume, making proofing water quality paramount. The spirit is distilled to near-neutral (often 95–96% ABV), so water character dominates the final product.

#### Water Effects on Vodka

| Water Type | Effect |
|------------|--------|
| **Soft water** | Silky texture; smooth mouthfeel; prevents haze |
| **Mineral-rich water** | Adds thickness and density; "heavy" feel |
| **High calcium/magnesium** | "Hard" taste |
| **Trace metals** | Undesirable bitterness |
| **Sodium (trace)** | Can enhance and "open up" flavor at very low levels |

**Premium vodka producers** typically use:
- **Artesian water**: Naturally filtered through soil/rock; consistent purity
- **Spring water**: Naturally soft with balanced minerals
- **RO/deionized water**: Maximum purity; may require reintroducing trace minerals for texture

#### pH Considerations for Vodka

The pH of proofing water influences perceived smoothness. While ethanol is slightly acidic, **neutral to slightly alkaline proofing water** (pH 7.0–8.0) is generally preferred for high-quality vodka.

### 13.5 Gin: Botanical Interactions and Louching

Gin proofing water affects not only clarity and mouthfeel but also how botanicals integrate over time.

#### Water pH Experiment (Distiller Magazine)

A controlled study tested six water sources (pH 5.46–8.4) for identical gin production. Results:

| Water Source | pH | Outcome |
|--------------|-----|---------|
| Demineralized | 7.0 | Full-bodied; good botanical integration |
| France | 5.46 | Good results |
| Germany | 7.1 | Good results |
| Fiji | 7.7 | Good results |
| Iceland | 8.4 | Poorest result — "very short flavor profile," "cloying texture," "rather hot" finish |

**Key finding**: Samples showed **increased flavor differences over six months** of storage, suggesting mineral content affects how gin evolves in the bottle.

#### Louching (Cloudiness)

**Louching** occurs when a clear spirit turns cloudy upon dilution or chilling. In gin, this happens because aromatic compounds — primarily terpenes like limonene, pinene, and camphene from botanicals — are soluble in high-proof alcohol but become insoluble as ABV drops or temperature falls.

**Science**: As ethanol concentration decreases and water molecules cluster more tightly, hydrophobic terpenes aggregate into microscopic droplets (100–500 nanometers) that scatter light, producing cloudiness.

**Mineral-induced louching**: Dissolved solids in proofing water (particularly calcium and magnesium carbonates from hard water) can cause or worsen louching by reacting with fatty acids to form insoluble compounds.

| Cause | Solution |
|-------|----------|
| Oil-based (botanical terpenes) | Bottle at higher proof; larger heads cut; chill filter; add neutral spirit drop-by-drop to re-dissolve |
| Mineral-based (hard water) | Use RO or distilled water for proofing |

**Louching is not a defect** — it indicates flavor-rich distillate. It's reversible: warming the spirit restores clarity as terpenes redissolve.

### 13.6 Distilling Water Quick Reference

#### Mash Water Targets

| Ion | Target | Max |
|-----|--------|-----|
| Calcium | 40–70 ppm | 150 ppm |
| Magnesium | 10–30 ppm | 40 ppm |
| Alkalinity (CaCO₃) | ≤50 ppm | 100 ppm |
| Chlorine | 0 | 0 |
| Iron | 0 | 0.3 ppm |

#### Proofing Water Targets

| Parameter | Target |
|-----------|--------|
| TDS | <10 ppm |
| Calcium | <2 ppm |
| All minerals | Near zero |

#### Spirit-Specific Considerations

| Spirit | Water Notes |
|--------|-------------|
| **Whiskey** | Mash water minerals affect fermentation character; use RO for proofing |
| **Vodka** | Proofing water is 60% of product; soft water for silky texture |
| **Gin** | Avoid high-pH water (>8); mineral content affects botanical integration over time |
| **Rum** | Similar to whiskey; mash water less critical than proofing |
| **Brandy** | Proofing water quality critical; usually RO |

---

## 14. Recommended Reading

- Palmer, John and Colin Kaminsky. *Water: A Comprehensive Guide for Brewers*. Brewers Publications.
- Brungard, Martin. [Bru'n Water](https://www.brunwater.com) — Free spreadsheet and extensive water knowledge base
- Palmer, John. [How to Brew](https://howtobrew.com) — Water chapter available free online

---

## 15. References

### Brewing References

- Brungard, Martin. Bru'n Water spreadsheet and documentation. brunwater.com
- Precision Fermentation. *Water Chemistry for Brewers: Key Considerations for Quality and Consistency*. 2022.
- Palmer, John and Colin Kaminski. *Water: A Comprehensive Guide for Brewers*. Brewers Publications, 2013. Chapters 1-7 and Appendices B-D extensively referenced for: phosphate buffering and calcium-phosphate reactions (Ch. 4), residual alkalinity and the Kolbach formula (Ch. 4), malt acidity and melanoidin chemistry (Ch. 5), sparge water acidification and alkalinity control methods including lime softening and acid additions (Ch. 6), sulfate-to-chloride ratio guidelines and salt addition calculations (Ch. 7), acidification charts for phosphoric and strong acids (Appendix B), and ion/salt/acid calculation procedures (Appendix C).
- Kolbach, Paul. "Der Einfluss Des Brauwassers auf das pH von Würze und Bier." *Monatsschrift fur Brauerei*, Berlin, 1953. (Translated by A. J. deLange.) Original residual alkalinity research.
- Troester, Kai. "The Effect of Brewing Water and Grist Composition on the pH of the Mash." Braukaiser.com, 2009. Research on buffering capacity as a function of grist ratio and crush size.
- deLange, A. J. "Alkalinity, Hardness, Residual Alkalinity and Malt Phosphate: Factors in the Establishment of Mash pH." *Cerevisia* 29(4), 2004.
- Hornsey, Ian. *The Oxford Companion to Beer*. Oxford University Press.
- Steele, Mitch. *IPA: Brewing Techniques, Recipes and the Evolution of India Pale Ale*. Brewers Publications.
- De Clerck, Jean. *A Textbook of Brewing*. Vol. 1. Siebel Institute, Chicago, 1994.
- Kunze, Wolfgang. *Technology Brewing and Malting*. International Edition. BLB Berlin, 1999.
- Bamforth, Charles. "pH in Brewing: An Overview." *MBAA Technical Quarterly* 38(1): 2-9, 2001.

### Distilling References

- "Water." *Distiller Magazine*. https://distilling.com/distillermagazine/water/
- "Mash Chemistry 101." *Distiller Magazine*. https://distilling.com/distillermagazine/mash-chemistry-101/
- "The Fuss Over Water." *Distiller Magazine*. https://distilling.com/distillermagazine/the-fuss-over-water/
- "Water, Distilled." *Artisan Spirit Magazine*. https://www.artisanspiritmag.com/blog-posts/water-distilled-3
- "Fine Tuning Water: Tips for Crafting Exceptional Spirits." Murphy and Son. https://www.murphyandson.co.uk/fine-tuning-water-tips-for-crafting-exceptional-spirits/
- "Water: It's More Than Just H's and O's." *Spirits & Distilling*. https://www.spiritsanddistilling.com/water-it-s-more-than-just-hs-and-os
- "How Water Affects Whiskey." Distiller. https://distiller.com/articles/water-affects-whiskey
- "Water in Whisky Production." Glenora Distillery, 2024. https://www.glenoradistillery.com/our-blog/2024/3/22/water-in-whisky-production
- "How Water Affects the Quality of Vodka." Nemiroff. https://nemiroff.vodka/en-uk/about-vodka-en-uk/how-water-affects-the-quality-of-vodka/
- "What is Louching: Exploring Gin's Cloudy Secret." Everglow Spirits. https://everglowspirits.com/what-is-louching-exploring-gins-cloudy-secret/
- Wilson, Dr. Craig (Diageo). Research on regional water effects on Scotch whisky character, cited in multiple sources.
