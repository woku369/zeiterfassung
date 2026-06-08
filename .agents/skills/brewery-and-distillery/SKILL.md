---
name: brewery-and-distillery
description: Use when brewing beer, making wine or cider (including country/fruit wines), fermenting mead, distilling spirits (bourbon, whiskey, Scotch, rum, brandy, tequila, vodka, gin, soju, shochu, arrack, arak, ouzo, raki, pastis, sambuca, absinthe), barrel aging, calculating alcohol content (ABV/OG/FG), troubleshooting fermentation issues, understanding yeast health, designing recipes, scaling batches, making sake, makgeolli, or other Asian fermented beverages, or when users mention brewing, fermentation, hops, malt, grapes, fruit wine, elderberry, dandelion, parsnip wine, barrel aging, oak, distillation, proof, specific gravity, yeast, ABV, mash, wort, must, spirits, bourbon, whiskey, mash bill, rum, cognac, tequila, mezcal, soju, shochu, makgeolli, sake, koji, nuruk, awamori, cheongju, arrack, arak, ouzo, raki, pastis, sambuca, anise spirits, punch, Swedish punsch, or louche, barleywine, barley wine, old ale, strong ale, parti-gyle, high-gravity brewing, wee heavy.
---
# Brewery and Distillery Assistant

## Table of Contents
- [Purpose](#purpose)
- [When to Use](#when-to-use)
- [What Is It?](#what-is-it)
- [Workflow](#workflow)
- [Common Patterns](#common-patterns)
- [Guardrails](#guardrails)
- [Quick Reference](#quick-reference)

## Purpose

Brewery and Distillery Assistant helps you ferment and distill with confidence by combining:

- **Fermentation science** (yeast biology, sugar conversion, temperature control, pH management)
- **Brewing technique** (mashing, lautering, boiling, hopping, conditioning)
- **Winemaking craft** (grape selection, crushing, pressing, malolactic fermentation, aging)
- **Distillation principles** (cuts, reflux, congeners, proof adjustment)
- **Calculation precision** (OG/FG, ABV, IBU, SRM, dilution, blending)
- **Troubleshooting methodology** (stuck fermentation, off-flavors, contamination)
- **Recipe design** (grain bills, hop schedules, yeast selection, water chemistry)

This moves you from following recipes blindly to understanding fermentation principles, so you can design, troubleshoot, and create.

## When to Use

Use this skill when:

- **Brewing beer**: All-grain, extract, or partial mash; any style from lagers to wild ales
- **Making wine**: Grape wines through aging; wine chemistry, SO₂ management, faults
- **Country wines**: Fruit wines (berry, stone fruit, citrus), flower wines (elderflower, dandelion), vegetable wines (parsnip, carrot), grain wines
- **Fermenting mead**: Traditional, melomel, metheglin, braggot; honey selection and nutrient management
- **Making cider**: Apple selection, tannin balance, carbonation methods
- **Distilling spirits**: Wash preparation, still operation, cuts, aging, proofing; world whiskeys (bourbon, Scotch, Irish, Japanese), rum (regional styles), brandy (Cognac, Armagnac), tequila/mezcal, vodka, gin, soju, shochu, awamori, liqueurs (where legal)
- **East Asian beverages**: Sake brewing, soju (traditional and modern), shochu (honkaku and korui), makgeolli (Korean rice wine), cheongju, awamori, koji and nuruk fermentation science
- **Barrel aging**: Oak science, oxygen transfer, rotation schedules, alternatives (chips, spirals, MOX)
- **Wild fermentation**: Spontaneous fermentation, Brett/LAB management, traditional indigenous beverages
- **Calculations**: ABV from gravity readings, IBU estimates, dilution math, batch scaling, refractometer corrections
- **Troubleshooting**: Stuck fermentation, off-flavors, contamination diagnosis, clarity issues
- **Recipe design**: Building grain bills, hop schedules, yeast pairing, water adjustment
- **Equipment questions**: Fermenters, kettles, stills, electric brewing systems, temperature control, hydrometers, refractometers
- **Ingredient science**: Malt types, hop varieties, yeast strains (100+ strains documented), adjuncts, oak, honey varietals
- **Legal considerations**: Distillation laws, homebrew competition labeling, regional regulations

Trigger phrases: "how do I brew", "fermentation", "ABV calculator", "specific gravity", "stuck fermentation", "off-flavor", "hop schedule", "grain bill", "yeast starter", "distilling", "proof", "mead", "cider", "wine making", "country wine", "fruit wine", "elderberry wine", "dandelion wine", "parsnip wine", "flower wine", "barrel aging", "oak aging", "wild fermentation", "spontaneous fermentation", "Brett", "sour beer", "lambic", "refractometer", "honey", "metheglin", "braggot", "bourbon", "whiskey", "whisky", "Scotch", "rye whiskey", "mash bill", "rum", "brandy", "cognac", "tequila", "mezcal", "vodka", "gin", "botanicals", "pot still", "column still", "heads", "hearts", "tails", "cuts", "aging spirits", "liqueur", "water chemistry", "mash pH", "sulfate", "chloride", "calcium", "Burtonize", "water profile", "gypsum", "residual alkalinity", "soju", "shochu", "makgeolli", "sake", "koji", "nuruk", "awamori", "cheongju", "Korean rice wine", "Korean spirit", "Japanese spirit", "arrack", "arak", "ouzo", "raki", "pastis", "sambuca", "mastika", "anise spirit", "absinthe", "punch", "Swedish punsch", "Batavia arrack", "toddy", "coconut arrack", "louche", "anethole", "chinchon", "anis", "barleywine", "barley wine", "old ale", "strong ale", "parti-gyle", "high-gravity brewing", "wee heavy", "Old Foghorn", "Bigfoot"

## What Is It?

Brewery and Distillery Assistant is a comprehensive fermentation guide that teaches through principles, not just steps. Drawing from brewing scientists (Fix, Palmer, White/Zainasheff), winemakers (Goode, Smith, Peynaud), mead makers (Schramm), distillers (Owens, Dikty, Hicks, Parsons), wild fermentation experts (Katz), and academic research (Handbook of Enology, fruit wine science), it provides:

1. **Why before how**: Science and rationale before procedure
2. **Precision tools**: Gravity readings, temperature logs, pH monitoring, timing
3. **Sensory + measurement**: "Fermentation should smell like fresh bread" + "Final gravity 1.010-1.014"
4. **Reproducible methods**: Ratios, formulas, calculators (ABV, IBU, dilution)
5. **Style context**: How traditions and regional practices inform technique

**Quick example:**

**User asks**: "My beer fermentation seems stuck at 1.020 but I was targeting 1.010. What's wrong?"

**Brewery Assistant response**:
1. **Diagnosis**: Likely causes—yeast health issue, fermentation temperature drop, or mash temperature was too high (leaving unfermentable dextrins).
2. **Immediate check**: What's the current temperature? Optimal range for most ale yeasts is 64-72°F. If it dropped below 60°F, yeast may have gone dormant.
3. **Yeast health**: Did you make a starter? Pitch rate should be ~0.75 million cells/mL/°P for ales. Underpitching causes stressed yeast that quit early.
4. **Mash analysis**: What was your mash temperature? Above 156°F creates more unfermentable sugars (dextrins), resulting in higher FG.
5. **Recovery options**: (a) Warm to 68-70°F and swirl to rouse yeast, (b) pitch fresh yeast (high-attenuating strain like US-05), (c) if mash was hot, accept higher FG as the beer may simply be less fermentable.
6. **Science**: Yeast converts fermentable sugars (maltose, glucose) but cannot digest dextrins. Apparent attenuation = (OG-FG)/(OG-1.000) × 100.

**Result**: User understands potential causes (temp, yeast, mash), has diagnostic steps, recovery options, and science to prevent future issues.

## Workflow

Copy this checklist and track your progress:

```
Fermentation Project Progress:
- [ ] Step 1: Define style/goal and key parameters
- [ ] Step 2: Design recipe (ingredients, calculations)
- [ ] Step 3: Prepare water and sanitize equipment
- [ ] Step 4: Execute mash/crush/must preparation
- [ ] Step 5: Manage fermentation (pitch, monitor, control)
- [ ] Step 6: Condition, clarify, package
```

**Step 1: Define style and parameters**

Specify what you're making, target ABV, bitterness (IBU), color (SRM/EBC), carbonation level. Identify if goal is recipe execution, clone attempt, style exploration, or troubleshooting. Know your equipment limitations (batch size, temperature control).

**Step 2: Design recipe**

Build ingredient list with calculations:
- **Beer**: Grain bill (base + specialty), hop schedule (timing, amounts, target IBU), yeast selection, water profile
- **Wine**: Grape/fruit selection, target sugar level (Brix/specific gravity), acid adjustment, yeast choice
- **Mead**: Honey variety, nutrient schedule (TOSNA or traditional), target sweetness
- **Spirits**: Wash recipe (grain, sugar, fruit), target alcohol for distillation

Reference [resources/template.md](resources/template.md) for recipe templates.

**Step 3: Prepare water and sanitize**

Water chemistry affects flavor extraction and yeast health. Adjust pH (5.2-5.6 for mash), mineral content for style. **Sanitation is paramount**—anything touching cooled wort/must must be sanitized (Star San, iodophor, or equivalent).

**Step 4: Execute production**

- **Beer**: Mash (conversion, lautering), boil (hops, timing), cool rapidly, transfer
- **Wine**: Crush, press (timing depends on color extraction needs), sulfite if desired
- **Mead**: Dissolve honey, rehydrate yeast, prepare nutrients
- **Distillation**: Ferment wash completely, then distill with proper cuts

See [resources/methodology.md](resources/methodology.md) for technique deep-dives.

**Step 5: Manage fermentation**

- **Pitch**: Proper yeast count, oxygenation for initial growth
- **Monitor**: Daily gravity checks (if accessible), temperature logging, airlock activity
- **Control**: Temperature stability (±2°F ideal), timing for additions (nutrients, dry hops)
- **Checkpoints**: Krausen formation (12-24h), krausen fall (active fermentation slowing), terminal gravity (stable 3+ days)

**Step 6: Condition and package**

- **Clarify**: Cold crash, fining agents (gelatin, bentonite, isinglass), filtration
- **Carbonate**: Priming sugar (bottles), force carbonation (kegs), méthode traditionnelle (sparkling wine)
- **Age**: Time requirements vary (lagers: 4-6 weeks cold, mead: 6-12 months, spirits: years in oak)
- **Package**: Bottles, kegs, barrels—each with specific procedures

Self-assess using [resources/evaluators/rubric_brewery.json](resources/evaluators/rubric_brewery.json). **Minimum standard**: Average score ≥ 3.5.

## Common Patterns

**Pattern 1: Recipe Design and Execution**
- **Goal**: Create or brew a specific beer/wine/mead style
- **Approach**: Define style parameters, calculate ingredients, execute with precision, monitor fermentation
- **Key elements**: OG/FG targets, IBU calculation, yeast selection rationale, fermentation temperature plan
- **Output**: Completed batch + documented process for reproducibility
- **Example**: American IPA → 1.065 OG, 1.012 FG, 65 IBU, Citra/Mosaic hops, US-05 yeast at 66°F

**Pattern 2: Troubleshooting Fermentation Issues**
- **Goal**: Diagnose and fix stuck fermentation, off-flavors, or contamination
- **Approach**: Systematic diagnosis (temperature, yeast, sugar, contamination), targeted intervention
- **Key framework**: Temperature → Yeast health → Fermentability → Contamination check
- **Corrections**:
  - Stuck fermentation → Warm, rouse, repitch if needed
  - Acetaldehyde (green apple) → More conditioning time, warmer
  - Diacetyl (butter) → Diacetyl rest (raise temp at end)
  - Sulfur (eggs) → Time, healthy yeast
  - Sourness → If unintended, likely contamination (Lactobacillus/Pediococcus)
- **Output**: Diagnosed problem + corrective action + prevention strategy
- **Example**: Diacetyl in lager → Raise to 65°F for 3-5 days before cold conditioning (diacetyl rest)

**Pattern 3: Calculation and Scaling**
- **Goal**: Calculate ABV, scale recipe, adjust dilution, estimate IBU
- **Approach**: Apply standard formulas with precision, account for system efficiency
- **Key formulas**:
  - ABV = (OG - FG) × 131.25
  - IBU = (oz hops × %AA × Utilization × 7489) / gallons
  - Dilution: C1V1 = C2V2
  - Priming sugar: ~2.5-3.0 volumes CO2 typical for ales
- **Output**: Accurate calculations for recipe planning or adjustment
- **Example**: OG 1.052, FG 1.010 → ABV = (1.052-1.010) × 131.25 = 5.5%

**Pattern 4: Yeast Management and Starters**
- **Goal**: Ensure adequate healthy yeast for clean fermentation
- **Approach**: Calculate pitch rate, make starter if needed, monitor viability
- **Key elements**:
  - Pitch rate: 0.75M cells/mL/°P (ales), 1.5M cells/mL/°P (lagers)
  - Starter: 10:1 ratio (100g DME per liter water), stir plate if possible
  - Viability: Decreases ~20% per month from manufacture
- **Output**: Properly pitched fermentation with healthy yeast
- **Example**: 5-gallon batch at 1.060 (15°P) needs ~285 billion cells; fresh Wyeast pack has ~100B, so make 2L starter

**Pattern 5: Water Chemistry Adjustment**
- **Goal**: Modify water to match style requirements
- **Approach**: Start with water report, adjust minerals for target profile
- **Key profiles**:
  - Pilsner: Very soft (low minerals, <50ppm each)
  - IPA: High sulfate (150-300ppm), moderate chloride (50-75ppm)
  - Stout: Higher chloride (100-150ppm), moderate sulfate
  - Mash pH target: 5.2-5.6 (room temp reading)
- **Common additions**: Gypsum (sulfate/calcium), calcium chloride, lactic/phosphoric acid for pH
- **Output**: Water profile matched to style + mash pH in range
- **Example**: Soft water + 8g gypsum per 5 gal = ~150ppm sulfate boost for West Coast IPA

**Pattern 6: Country Wine Production**
- **Goal**: Make fruit, flower, vegetable, or grain wines (non-grape)
- **Approach**: Balance sugar, acid, and body that grapes provide naturally
- **Key elements**:
  - Sugar: Most fruits need 2-3 lb/gallon added sugar for wine strength
  - Acid: Lemon juice or acid blend (target pH 3.2-3.5)
  - Body: Raisins (8-12 oz/gal), grape concentrate, or tannin/tea
  - Pectin enzyme: Essential for fruit wines to prevent haze
- **Categories**: Stone fruits, berries, citrus, flowers, vegetables, grains
- **Output**: Balanced country wine with proper fermentation
- **Example**: Elderberry wine → 3 lb berries, 3 lb sugar, 8 oz raisins, 1 lemon, pectin enzyme, wine yeast; heat berries; ferment 5 days on pulp; age 2+ years

**Pattern 7: Barrel Aging Management**
- **Goal**: Age wine or spirits in oak barrels with proper protocols
- **Approach**: Manage oxygen exposure, extraction, and maintenance
- **Key elements**:
  - Oxygen transfer: 1.66-2.5 mL/L/month (new French oak)
  - Temperature: 12-18°C (54-64°F) optimal; avoid >25°C
  - Topping up (wine): Every 2 weeks initially, monthly later
  - Rotation: 4-5 year program typical; new → used → neutral → retire
- **Alternatives**: Oak chips (2-4 weeks), spirals (6-10 weeks), micro-oxygenation
- **Output**: Properly aged product with controlled oak influence
- **Example**: Barrel program → 25% new barrels annually, best lots to new wood, cascade older barrels, retire at 4-5 years

## Guardrails

**Critical requirements:**

1. **Sanitation is non-negotiable**: Anything touching product after boil (beer) or must (wine) must be sanitized. One contaminated surface can ruin a batch. Use Star San, iodophor, or equivalent; follow contact time instructions.

2. **Temperature control during fermentation**: Most fermentation issues trace to temperature. Ale yeasts: 60-72°F (strain dependent). Lager yeasts: 48-55°F. Wild/sour: varies. ±2°F stability is ideal. Temperature swings stress yeast, causing off-flavors.

3. **Pitch adequate healthy yeast**: Underpitching is the most common homebrewing error. Calculate pitch rate for OG and batch size. Use starters for liquid yeast. Check manufacture date (viability drops ~20%/month).

4. **Take gravity readings**: OG and FG are essential for calculating ABV and confirming fermentation complete. Stable gravity over 3+ days indicates fermentation done. Never bottle/keg while actively fermenting (risk of explosion).

5. **Understand fermentability**: Not all sugars are fermentable. Mash temp affects fermentability (higher = more dextrins = less fermentable = higher FG). Honey is highly fermentable (~95%). Lactose is unfermentable.

6. **Time heals many flaws**: Young beer/wine/mead often tastes "green" or harsh. Conditioning time allows yeast to clean up byproducts (acetaldehyde, diacetyl), flavors to meld, and clarity to improve. Patience is a key ingredient.

7. **pH matters throughout**: Mash pH (5.2-5.6) affects enzyme activity and flavor. Wine must pH affects microbial stability and color. Distillation pH affects congener carryover. Measure and adjust.

8. **Legal compliance for distillation**: Distilling alcohol requires permits in most jurisdictions. This skill provides educational information. Users are responsible for understanding and complying with local laws.

**Common pitfalls:**

- ❌ **Ignoring sanitation**: "Just a quick rinse" leads to infected batches. Sanitize everything.
- ❌ **Fermenting too warm**: Creates fusel alcohols (hot, solvent-like), esters (fruity but can be excessive), and stressed yeast. Cooler is usually better.
- ❌ **Underpitching yeast**: Leads to slow/stuck fermentation, off-flavors, stressed yeast. Use a calculator and make starters.
- ❌ **Bottling too early**: Active fermentation in sealed bottles = bottle bombs. Wait for stable gravity 3+ days.
- ❌ **Not taking notes**: Reproducibility requires records. Log everything: dates, temps, gravities, ingredients, observations.
- ❌ **Chasing equipment**: Good fermentation fundamentals matter more than fancy equipment. Master basics first.

## Quick Reference

**Key resources:**

- **[resources/recipes.md](resources/recipes.md)**: Curated recipes — IPAs, stouts, porters, pilsners, Belgian styles, English styles, lagers, historical ales, meads, ciders
- **[resources/yeast-guide.md](resources/yeast-guide.md)**: Comprehensive yeast reference — 100+ strains from 11 manufacturers (Wyeast, White Labs, Omega, Imperial, Lallemand, Fermentis, etc.), specs, equivalencies, selection by style, kveik strains
- **[resources/template.md](resources/template.md)**: Recipe templates for beer, wine, mead, spirits, and country wines; calculation worksheets; fermentation logs
- **[resources/methodology.md](resources/methodology.md)**: Advanced fermentation science, professional techniques, style guides, chemistry deep-dives
- **[resources/refractometer-guide.md](resources/refractometer-guide.md)**: Refractometer corrections — WCF determination, alcohol correction formulas (Terrill, Novotný), beverage-specific guidance
- **[resources/equipment-guide.md](resources/equipment-guide.md)**: Equipment recommendations — electric brewing systems (Grainfather, Anvil, Spike), fermentation temp control, glycol chillers, digital monitors, stills
- **[resources/fermentation-biochemistry.md](resources/fermentation-biochemistry.md)**: Fermentation biochemistry reference — ester biosynthesis (acetyl-CoA), fusel alcohols (Ehrlich pathway), diacetyl/VDK metabolism, DMS, oxygen requirements, beer stability (haze, staling, 2-trans-nonenal), carbonation (Henry's Law), clarification, foam science, packaging

**Science modules:**

- **[modules/core-guidance.md](modules/core-guidance.md)**: Core fermentation principles, yeast biology, production fundamentals
- **[modules/biab-brewing.md](modules/biab-brewing.md)**: BIAB (Brew in a Bag) all-grain brewing — single-vessel method, equipment (kettle/bag/pulley), water calculations, finer crush, mash parameters, the squeeze debate (debunked), efficiency optimization, sparge options (no-sparge, dunk, pour-over), high-gravity workarounds, best practices
- **[modules/hop-science.md](modules/hop-science.md)**: Comprehensive hop reference — biology, chemistry (alpha/beta acids, oils, thiols, polyphenols), products (T-90/T-45/Cryo/extract), hopping techniques, IBU science, dry hopping, biotransformation, hop creep, skunking, 70+ variety profiles, style pairing, breeding history
- **[modules/malt-science.md](modules/malt-science.md)**: Malt and grain science — barley biology, malting process, malt analysis (COA interpretation), base/specialty/crystal/roasted malts, alternative grains (gelatinization temps), adjunct sugars, enzymatic activity (7 enzymes), grain bill design, smoked malts (smoke chemistry, commercial products, DIY smoking, wood selection, smoked beer styles)
- **[modules/lager-science.md](modules/lager-science.md)**: Lager brewing science — *S. pastorianus* biology, fermentation profiles, decoction mashing (triple/double/single/Hochkurz), lagering, diacetyl rest, water chemistry for lagers, 14 style profiles, pitch-to-package schedules, troubleshooting
- **[modules/water-chemistry.md](modules/water-chemistry.md)**: Water chemistry — ions (Ca, Mg, Na, SO₄, Cl, HCO₃), mash pH and residual alkalinity (Kolbach formula), phosphate buffering, classic profiles (Burton, Pilsen, Dublin), modern profiles (NEIPA, West Coast IPA), chloride:sulfate ratios, treatment methods, building from RO
- **[modules/cleaning-sanitation.md](modules/cleaning-sanitation.md)**: Cleaning and sanitation — hot-side vs cold-side, PBW specs, Star San (pH monitoring, shelf life, spray bottle method), Iodophor, heat sanitization, equipment-specific procedures, brew day workflow, infection troubleshooting
- **[modules/kegging-draft.md](modules/kegging-draft.md)**: Kegging and draft systems — Corny keg types (ball lock/pin lock), CO₂ systems, line sizing and balancing (resistance formula), forced carbonation (3 methods + chart), keezer/kegerator builds, nitro draft (75/25 gas, stout faucet), maintenance
- **[modules/adjuncts-ingredients.md](modules/adjuncts-ingredients.md)**: Adjuncts and specialty ingredients — fruit (9 varieties with quantities), coffee (4 methods), chocolate/cacao, vanilla, spices/herbs (15 entries), coconut, lactose, maple syrup, peanut butter, chile peppers, honey, oak
- **[modules/wine-science.md](modules/wine-science.md)**: Wine fermentation science — yeasts, SO₂, flavor chemistry, faults, sweet wines, oak science, Brettanomyces management
- **[modules/mead-science.md](modules/mead-science.md)**: Comprehensive mead making — fermentation phases, nutrient management (TOSNA), honey science, 15+ varietal honeys, yeast selection, troubleshooting
- **[modules/cider-science.md](modules/cider-science.md)**: Cider and perry science — apple classification, juice preparation, fermentation, keeving, regional styles, pét-nat, ice cider, back-sweetening, troubleshooting
- **[modules/country-wine.md](modules/country-wine.md)**: Country wine production — stone fruits, berries, citrus, tropical fruits, flower wines, vegetable wines, grain wines; 50+ recipes with science
- **[modules/wild-fermentation.md](modules/wild-fermentation.md)**: Wild/spontaneous fermentation — wild yeast biology, traditional meads (t'ej, balché), lambic process, indigenous grain beers (tesgüino, chicha, kvass)
- **[modules/distillation-science.md](modules/distillation-science.md)**: Comprehensive spirits guide — still design, spirit runs and cuts, gin production and botanicals, **world whiskeys** (bourbon/Tennessee/rye, Scotch regions, Irish/Japanese/Canadian), mash bill science, **vodka**, **brandy** (Cognac/Armagnac/Calvados/Pisco/Grappa), **rum** (regional styles, agricole, cachaça), **tequila and mezcal**, **baijiu** (qu starters, four aroma categories, zeng distillation), liqueurs, amaro, vermouth, botanical safety, whiskey modification, **arrack** (coconut/toddy, Batavia with ragi fermentation, Middle Eastern arak, Swedish punsch), **ouzo** (PDO regulations, Lesbos distilleries), **anise spirits** (raki, pastis, sambuca, mastika, chinchon, louche effect chemistry)
- **[modules/korean-japanese-spirits.md](modules/korean-japanese-spirits.md)**: Korean and Japanese spirits — **soju** (history, traditional vs modern, brands, drinking culture, legal classification), **expanded shochu** (honkaku vs korui, base ingredients, koji types, awamori/kusu aging, geographic indications), **makgeolli** (nuruk fermentation science, pasteurized vs saeng, craft movement, cheongju/dongdongju/yakju)
- **[modules/sake-science.md](modules/sake-science.md)**: Sake brewing science — koji biochemistry, moto preparation, multiple parallel fermentation, moromi stages, shochu, mirin, modern classifications
- **[modules/barrel-aging.md](modules/barrel-aging.md)**: Barrel aging science — oxygen transfer rates, wood chemistry, toasting vs charring, management protocols, rotation schedules, solera systems, oak alternatives
- **[modules/recipe-modification.md](modules/recipe-modification.md)**: Recipe modification formulas — ABV, IBU, SRM, gravity calculations, scaling, mash conversions, carbonation, water chemistry
- **[modules/distillation-calculations.md](modules/distillation-calculations.md)**: Distillation calculations — sugar wash, distillate yield, dilution, proofing, blending, Pearson's Square, cuts, column design
- **[modules/legal-considerations.md](modules/legal-considerations.md)**: Legal requirements — US federal/state distillation laws, international regulations, homebrew competition labeling (BJCP/AHA rules)

**Calculation scripts (Python):**

- **[scripts/brewing_calc.py](scripts/brewing_calc.py)**: ABV, IBU (Tinseth/Rager), SRM, gravity, efficiency, mash calculations, carbonation, yeast pitch rate, recipe analysis
- **[scripts/water_calc.py](scripts/water_calc.py)**: Salt additions, ion profiles, residual alkalinity, SO₄:Cl ratio, build-from-RO, acid additions
- **[scripts/distilling_calc.py](scripts/distilling_calc.py)**: Sugar wash, distillate yield, dilution, proofing, blending, Pearson's Square, vapor speed, column design, cuts

**Evaluation:**

- **[resources/evaluators/rubric_brewery.json](resources/evaluators/rubric_brewery.json)**: Quality criteria for fermentation guidance and execution

**Essential formulas:**

| Calculation | Formula | Notes |
|-------------|---------|-------|
| ABV (simple) | (OG - FG) × 131.25 | Quick estimate, accurate to ±0.3% |
| ABV (accurate) | 76.08(OG-FG)/(1.775-OG) × (FG/0.794) | Better for high-gravity |
| Apparent attenuation | (OG - FG) / (OG - 1.000) × 100 | Percentage of sugars consumed |
| IBU (Tinseth) | (oz × %AA × U × 7489) / gallons | U = utilization factor by time |
| Priming sugar | (volumes CO2 - residual) × grams factor × liters | ~4g/L corn sugar for 2.5 vol |
| Dilution | C1 × V1 = C2 × V2 | Proofing spirits, adjusting gravity |
| Pitch rate (ales) | 0.75M cells/mL/°P | Higher gravity = more yeast needed |
| Pitch rate (lagers) | 1.5M cells/mL/°P | Double the ale rate |

**Gravity/ABV quick reference:**

| OG | Expected FG (75% atten) | ABV |
|----|------------------------|-----|
| 1.040 | 1.010 | 3.9% |
| 1.050 | 1.012 | 5.0% |
| 1.060 | 1.015 | 5.9% |
| 1.070 | 1.017 | 7.0% |
| 1.080 | 1.020 | 7.9% |
| 1.100 | 1.025 | 9.8% |

**Fermentation temperature ranges:**

| Yeast Type | Optimal Range | Notes |
|------------|---------------|-------|
| American ale | 60-72°F | Clean at low end, fruity at high |
| English ale | 64-72°F | More esters than American |
| Belgian ale | 65-80°F | Phenols and esters at high temps |
| German lager | 48-55°F | Clean, requires cold conditioning |
| Wine yeast | 55-75°F | Strain dependent |
| Mead yeast | 60-75°F | Slow and cool for clean results |

**Off-flavor quick diagnosis:**

| Off-Flavor | Tastes Like | Likely Cause | Fix |
|------------|-------------|--------------|-----|
| Acetaldehyde | Green apple | Young beer, stressed yeast | More conditioning time, warmer |
| Diacetyl | Butter, butterscotch | Incomplete fermentation | Diacetyl rest (raise temp 3-5 days) |
| DMS | Cooked corn | Short/weak boil, slow cooling | 60+ min vigorous boil, rapid chill |
| Fusel alcohols | Hot, solvent | Fermentation too warm | Ferment cooler next time |
| Phenolic | Band-aid, medicinal | Wild yeast, chlorine in water | Better sanitation, use campden for chlorine |
| Sulfur | Rotten eggs | Stressed yeast (lagers especially) | Time, healthy yeast, warm conditioning |
| Sourness | Vinegar, sour | Bacterial contamination | Prevention—cannot fix |

**Common water additions (per 5 gallons):**

| Addition | Amount | Effect |
|----------|--------|--------|
| Gypsum (CaSO4) | 1 tsp (~4g) | +60 ppm Ca, +150 ppm SO4 |
| Calcium chloride | 1 tsp (~4g) | +70 ppm Ca, +125 ppm Cl |
| Lactic acid (88%) | 1 mL | Drops mash pH ~0.1 |
| Phosphoric acid (10%) | 1 mL | Drops mash pH ~0.05 |

**When to escalate:**

- Commercial-scale production licensing and equipment
- Complex water chemistry beyond basic adjustments (consult Bru'n Water or similar tools)
- Medical concerns about alcohol consumption
- Specific legal questions about permits in your jurisdiction
→ Consult specialized resources, regulatory bodies, or professionals

**Full module index:** See **[_toc.md](_toc.md)** for complete table of contents with all modules and resources.

**Inputs required:**

- **Production goal**: What you want to make, target style parameters
- **Equipment**: Batch size, temperature control capability, fermentation vessels
- **Current state** (if troubleshooting): Gravity readings, temperature log, observations
- **Ingredients available**: What you're working with, substitution questions

**Outputs produced:**

- `fermentation-guide.md`: Complete production guide with recipe, calculations, schedule, troubleshooting, and style context
