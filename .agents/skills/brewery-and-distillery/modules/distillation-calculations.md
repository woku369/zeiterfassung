# Distillation Calculations Guide

Formulas and methods for wash preparation, distillation yield estimation, dilution, proofing, blending, column design, and equipment sizing. When users ask about modifying a distillation recipe or planning a run, use the reference formulas below and the companion script.

## Companion Script

| Script | Purpose |
| --- | --- |
| `scripts/distilling_calc.py` | Python library: sugar wash, wash ABV, distillate yield, dilution, blending, Pearson's Square, heating time, vapor speed, column design, cuts estimation, bottle yield |

---

## ABV and Proof

```
US Proof = ABV × 2
ABV = US Proof / 2
```

UK proof (historical, "Sikes") differs: UK proof ≈ ABV × 1.75. Modern UK labeling uses ABV.

### ABV from Gravity

```
ABV = (OG - FG) × 131.25
```

For high-gravity washes (>1.080 OG), use the alternate formula:

```
ABV = 76.08 × (OG - FG) / (1.775 - OG) × (FG / 0.794)
```

---

## Sugar Wash Calculations

### Sugar Needed for Target ABV

Rule of thumb: **1 lb sugar per gallon ≈ 5.9% potential ABV.**

More precise formula:

```
Sugar (grams) = Volume (liters) × Target ABV% × 17
```

| Target ABV | Sugar per gallon | Sugar per 5 gallons |
| --- | --- | --- |
| 5% | 0.85 lb | 4.2 lb |
| 8% | 1.35 lb | 6.8 lb |
| 10% | 1.70 lb | 8.5 lb |
| 12% | 2.03 lb | 10.2 lb |
| 14% | 2.37 lb | 11.9 lb |
| 18% | 3.05 lb | 15.3 lb |
| 20% | 3.39 lb | 17.0 lb |

### Practical Limits

- Standard baker's yeast: max ~14% ABV
- Wine yeast: max ~16–18% ABV
- Turbo yeast: max ~18–21% ABV (often produces off-flavors above 15%)
- Recommended for clean distillate: **7–10% ABV wash** (ferments fast, fewer congeners)

### OG from Sugar

```
OG = ((sugar_lbs × 46) / volume_gallons) × 0.001 + 1
```

Pure sugar has a PPG (Points Per Pound Per Gallon) of 46.

### Glucose vs. Sucrose

Glucose (dextrose) requires **12.5% more weight** than sucrose for the same fermentable sugar content.

```
Glucose_weight = Sucrose_weight × 1.125
```

---

## Grain Mash Yield

### Predicted Spirit Yield (PSY)

Used in Scotch whisky production. The Dolan factor (1976):

```
PSY (liters absolute alcohol per tonne) = Fermentable_Extract × 6.06
```

Where `Fermentable_Extract = (extract × fermentability) / 100`.

Typical PSY values:
| Grain | PSY (Laa/tonne) |
| --- | --- |
| Distilling malt (barley) | 400–420 |
| Wheat | 380–410 |
| Corn/maize | 370–400 |
| Rye | 350–380 |

### Grain Mash OG

```
OG = ((grain_lbs × PPG × efficiency) / volume_gallons) × 0.001 + 1
```

Distilling mash efficiency is typically **55–70%** (lower than brewing due to coarser crush and less rigorous lautering).

### Starch Content by Grain

| Grain | Starch Content | Notes |
| --- | --- | --- |
| Corn | 70–75% | Requires cooking to gelatinize (150–170°F) |
| Wheat | 65–70% | Gelatinizes at lower temp than corn |
| Barley (malted) | 58–63% | Self-converting (has enzymes) |
| Rye | 55–65% | Very sticky; use rice hulls |
| Oats | 55–60% | Low enzyme content |
| Rice | 75–80% | Requires cereal mash |

Unmalted grains need external enzymes (malted barley at 10–20% of grist, or commercial amylase enzymes) for starch conversion.

---

## Distillate Yield Estimation

### From Wash ABV

```
Alcohol_in_wash (gal) = wash_volume (gal) × wash_ABV / 100
Recovered_alcohol = Alcohol_in_wash × collection_efficiency
Distillate_volume = Recovered_alcohol / (collection_ABV / 100)
```

Typical collection efficiency: **80–90%** (home stills). Commercial: **90–95%**.

### From Sugar Weight

```
Pure ethanol yield ≈ 0.55 L per kg sugar (practical)
```

Theoretical maximum: 0.648 L per kg (Gay-Lussac). Practical yield is ~85–90% of theoretical due to yeast metabolism byproducts.

| Sugar (kg) | Pure Ethanol (L) | At 75% ABV (L) | At 40% ABV (L) | 750mL Bottles |
| --- | --- | --- | --- | --- |
| 1 | 0.55 | 0.73 | 1.38 | 1.8 |
| 5 | 2.75 | 3.67 | 6.88 | 9.2 |
| 8 | 4.40 | 5.87 | 11.00 | 14.7 |
| 10 | 5.50 | 7.33 | 13.75 | 18.3 |

### Quick Yield Rule of Thumb

A 5-gallon wash at 10% ABV, run through a pot still, yields roughly:
- **2.5 L** of distillate at ~65% ABV (hearts + some heads/tails)
- **1.5 L** of hearts at ~60–65% ABV
- **4 L** when proofed down to 40% ABV (~5 bottles)

---

## Dilution and Proofing

### Dilution Formula (C₁V₁ = C₂V₂)

```
Final_Volume = (Spirit_ABV × Spirit_Volume) / Target_ABV
Water_to_Add = Final_Volume - Spirit_Volume
```

**Volume contraction warning:** When mixing ethanol and water, the resulting volume is slightly less than the sum of the parts (~3–4% contraction at ~50% ABV). Add water gradually and re-measure. The calculated amount will get you close, but always creep up on the target.

### Common Dilutions

| Spirit ABV | Target ABV | Water per Liter of Spirit |
| --- | --- | --- |
| 95% | 40% | 1,375 mL |
| 80% | 40% | 1,000 mL |
| 65% | 40% | 625 mL |
| 55% | 40% | 375 mL |
| 50% | 40% | 250 mL |

### Proofing Best Practices

1. Use distilled or RO water for dilution
2. Let the blend rest 24–48 hours before final measurement (allows molecular integration)
3. Measure at 60°F (15.56°C) for TTB-accurate proof, or 68°F (20°C) for international standards
4. Add water to spirit (not spirit to water) to avoid louching in anise spirits

---

## Temperature Correction

Alcohol hydrometers are calibrated at a specific temperature (usually 60°F / 15.56°C for TTB, or 68°F / 20°C internationally).

### Rule of Thumb

```
For every 1°C above calibration temperature: subtract 0.33% ABV from reading
For every 1°C below calibration temperature: add 0.33% ABV to reading
```

This is an approximation. For TTB-accurate proofing, use official Table 1 from the TTB Gauging Manual or AlcoDens software.

### Why It Matters

At 80°F (26.7°C) reading from a 60°F-calibrated hydrometer, the correction is approximately:
- Temperature difference: ~11°C
- Correction: ~3.6% ABV
- If hydrometer reads 45% ABV, actual is approximately 41.4% ABV

---

## Blending

### Two Spirits

```
Blended_ABV = (Volume_A × ABV_A + Volume_B × ABV_B) / (Volume_A + Volume_B)
```

### Pearson's Square

A method for calculating blend ratios to hit a target concentration. Works for ABV, acidity, sugar, or any blendable property.

```
         A ─────────── D = |C - B|    (parts of A)
              ╲   ╱
               ╲ ╱
          C ────╳
               ╱ ╲
              ╱   ╲
         B ─────────── E = |A - C|    (parts of B)
```

Where:
- **A** = concentration of solution A (higher)
- **B** = concentration of solution B (lower)
- **C** = desired target concentration
- **D** = parts of A needed
- **E** = parts of B needed

### Fortification

To raise ABV using a higher-proof spirit:

```
Spirit_needed = Wine_volume × (Target_ABV - Wine_ABV) / (Spirit_ABV - Target_ABV)
```

Example: Fortify 1 gallon of 12% wine to 18% using 40% brandy:
- Spirit = 1 gal × (18 - 12) / (40 - 18) = 1 × 6/22 = 0.273 gal (~35 oz)

---

## Equipment Calculations

### Heating Time

```
Time (min) = (Volume_gal × 8.33 × 453.59 × ΔT_celsius) / (Watts × 0.2389 × efficiency) / 60
```

| Volume | ΔT | Power | Efficiency | Time |
| --- | --- | --- | --- | --- |
| 5 gal | 65→173°F | 1500W | 80% | 66 min |
| 5 gal | 65→173°F | 2000W | 80% | 49 min |
| 5 gal | 65→173°F | 3000W | 80% | 33 min |
| 10 gal | 65→173°F | 2000W | 80% | 99 min |
| 10 gal | 65→173°F | 5500W | 80% | 36 min |

BTU conversion: `1 BTU/hr = 0.293 watts`

### Vapor Speed

```
Vapor_Speed (cm/s) = Vapor_Flow (cm³/s) / Column_Cross_Section (cm²)
```

Where vapor flow ≈ 0.84 cm³/s per watt (empirical approximation for water/ethanol steam).

| Column Diameter | 750W | 1500W | 2500W |
| --- | --- | --- | --- |
| 1.5" (38mm) | 55 cm/s | 111 cm/s | 185 cm/s |
| 2" (51mm) | 31 cm/s | 62 cm/s | 104 cm/s |
| 3" (76mm) | 14 cm/s | 28 cm/s | 46 cm/s |
| 4" (102mm) | 8 cm/s | 15 cm/s | 26 cm/s |

**Targets:**
- Packed columns (mesh, copper scrubbers): ≤50 cm/s (20 in/s)
- Plate columns (bubble cap, perforated): ≤100 cm/s (40 in/s)
- Above these speeds: flooding risk, poor separation

### Recommended Column Power

| Column Diameter | Min Watts | Max Watts |
| --- | --- | --- |
| 1.5" | 420 | 1400 |
| 2" | 750 | 2500 |
| 3" | 1690 | 5625 |
| 4" | 3000 | 10000 |

---

## Column Design

### HETP (Height Equivalent to a Theoretical Plate)

```
HETP (meters) ≈ packing_diameter_mm / 60
Number of Plates = Packing_Height / HETP
Required Height = Target_Plates × HETP
```

| Packing Type | HETP (cm) | Notes |
| --- | --- | --- |
| Copper mesh (SPP) | 1.5–2.5 | Best efficiency per height |
| Stainless steel scrubbers | 2.0–3.0 | Common, inexpensive |
| Raschig rings (6mm) | 1.0–1.5 | Good but harder to pack |
| Raschig rings (13mm) | 2.0–3.5 | Easier to pack, less efficient |
| Ceramic saddles | 2.5–4.0 | Good liquid distribution |
| Bubble cap plates | ~10–15 per plate | Per physical plate |

### Reflux Ratio

```
Reflux_Ratio = Liquid_Return / Distillate_Collected = (Vapor - Distillate) / Distillate
```

| Reflux Ratio | Behavior |
| --- | --- |
| 0 (no reflux) | Pot still mode — single pass, full flavor |
| 1:1 | Moderate purity increase |
| 3:1 | Good separation, common for vodka columns |
| 5:1+ | High purity, approaching azeotrope |
| Total reflux | Equilibrium — no product collected, maximum separation |

Operating reflux is typically **1.2–1.5× minimum reflux ratio** for energy efficiency.

### Theoretical Plates for Target Purity

| Target | Approximate Plates Needed |
| --- | --- |
| ~80% ABV (whiskey) | 3–5 |
| ~90% ABV (clean neutral) | 8–12 |
| ~95% ABV (near azeotrope) | 15–20+ |
| 95.6% ABV (ethanol-water azeotrope) | Physical limit — cannot exceed with standard distillation |

---

## Making Cuts

Congener boiling points determine where cuts fall:

| Compound | Boiling Point | Category | Character |
| --- | --- | --- | --- |
| Acetone | 133°F / 56°C | Foreshots | Solvent, nail polish remover |
| Methanol | 149°F / 65°C | Foreshots | Toxic in concentration — always discard |
| Ethyl acetate | 171°F / 77°C | Heads | Fruity, solvent-like |
| **Ethanol** | **173°F / 78°C** | **Hearts** | **Clean, sweet spirit** |
| 2-Propanol | 181°F / 83°C | Late heads | Rubbing alcohol |
| 1-Propanol | 207°F / 97°C | Tails | Harsh, oily |
| Water | 212°F / 100°C | Tails | Dilutes spirit |
| Butanol | 244°F / 118°C | Late tails | Fusel, hot |
| Amyl alcohol | 280°F / 138°C | Late tails | Fusel, banana-like |
| Furfural | 323°F / 162°C | Late tails | Bitter almond, bran |

### Estimated Cut Volumes

For a **stripping run** (first distillation), rough guidelines:

```
Foreshots: ~30 mL per gallon of wash (always discard)
Heads:     ~15% of total distillate
Hearts:    ~35–45% of total distillate
Tails:     ~40–50% of total distillate
```

For a **spirit run** (second distillation of low wines), the hearts fraction is larger because heads and tails are more concentrated and easier to separate.

**Never rely solely on temperature or volume.** Use your senses:
- **Foreshots**: Harsh solvent smell. Discard.
- **Heads→Hearts transition**: Solvent smell fades, sweetness appears. Transition gradually.
- **Hearts**: Clean, sweet, characteristic spirit flavor.
- **Hearts→Tails transition**: Wet cardboard, thin flavor, oily sheen on collection jar.
- **Tails**: Cereal, wet dog, oily. Save for re-distillation or discard.

---

## Bottle Yield

```
Bottles = Total_Volume_mL / Bottle_Size_mL
```

Standard bottle sizes:
| Size | mL |
| --- | --- |
| Miniature / nip | 50 |
| Half pint | 200 |
| Flask / half bottle | 375 |
| Standard (fifth) | 750 |
| Liter | 1000 |
| Handle / half gallon | 1750 |
