# Recipe Modification Guide

Formulas and methods for adjusting, scaling, and analyzing brewing recipes. When users ask about modifying a recipe, use the reference formulas below and the companion scripts in `scripts/`.

## Companion Scripts

| Script | Purpose |
| --- | --- |
| `scripts/brewing_calc.py` | Core brewing calculations: ABV, IBU, SRM, gravity, efficiency, mash, carbonation, yeast pitching, full recipe analysis |
| `scripts/water_calc.py` | Water chemistry: salt additions, ion profiles, residual alkalinity, SO₄:Cl ratio, building from RO, acid additions |

---

## Gravity Calculations

### Original Gravity from Grain Bill

```
Total Points = Σ (grain_lbs × PPG × efficiency)
OG = (Total Points / volume_gallons) × 0.001 + 1
```

- **PPG** (Points Per Pound Per Gallon): extract potential of each grain, typically 27–46
- **Efficiency**: decimal fraction. 72% = 0.72. Typical range: 65–80% for homebrewers.

Common PPG values:
| Grain | PPG |
| --- | --- |
| 2-Row Pale Malt | 37 |
| Pilsner Malt | 36 |
| Munich Malt | 34 |
| Vienna Malt | 35 |
| Wheat Malt | 37 |
| Crystal/Caramel 60L | 34 |
| Roasted Barley | 25 |
| Flaked Oats | 32 |
| Honey | 35 |
| Corn Sugar (dextrose) | 46 |
| Table Sugar (sucrose) | 46 |
| DME | 44 |
| LME | 36 |

### Plato ↔ Gravity Conversions

```
Gravity → Plato: P = -616.868 + (1111.14 × SG) - (630.272 × SG²) + (135.997 × SG³)
Plato → Gravity: SG = (P / (258.6 - ((P / 258.2) × 227.1))) + 1
```

### Pre-Boil Gravity

```
Boil_Gravity = (Batch_Volume / Boil_Volume) × (OG - 1) + 1
```

### Estimating Final Gravity

```
FG_points = OG_points × (1 - attenuation)
FG = (FG_points / 1000) + 1
```

Typical attenuation values: 65–80% for ales, 70–85% for lagers. Check yeast datasheet.

---

## ABV Calculations

### Standard Formula

```
ABV = (OG - FG) × 131.25
```

Accurate for beers under ~8% ABV.

### Alternate Formula (High-Gravity)

```
ABV = 76.08 × (OG - FG) / (1.775 - OG) × (FG / 0.794)
```

More accurate for high-gravity fermentations (>1.070 OG). Based on Cutaia, Reid, and Speers.

### Refractometer ABV (Post-Fermentation)

Refractometer readings after fermentation are inaccurate without correction because alcohol changes the refractive index. Use the Terrill formula:

```
Corrected FG = 1 + 0.006276 × FG_brix - 0.002349 × OG_brix
```

Where OG_brix and FG_brix are both refractometer readings corrected by WCF (typically 1.04). See `resources/refractometer-guide.md` for details.

---

## IBU Calculations

### Tinseth Method

The most widely used IBU formula. Accounts for both gravity and boil time.

```
Bigness Factor = 1.65 × 0.000125^(OG - 1)
Boil Time Factor = (1 - e^(-0.04 × time_minutes)) / 4.15
Utilization = Bigness × Boil_Time_Factor
IBU = Utilization × ((AA% / 100) × hop_oz × 7490) / volume_gallons
```

- Higher gravity → lower utilization (bigger beers extract less bitterness)
- Returns diminish after ~60 min; ~90 min approaches maximum utilization
- Use **boil gravity** (pre-boil), not OG, for best accuracy

### Rager Method

Alternative formula using hyperbolic tangent for utilization curve.

```
If time ≤ 5 min: Utilization = 0.01 × time
Else: Utilization = (18.11 + 13.86 × tanh((time - 31.32) / 18.27)) / 100

If OG > 1.050: Gravity_Adjustment = (OG - 1.050) / 0.2
Else: Gravity_Adjustment = 0

IBU = (hop_oz × Utilization × AA% × 7489) / (volume_gal × (1 + Gravity_Adjustment))
```

### Altitude Adjustment

Higher altitudes reduce boiling point, lowering hop utilization.

```
Altitude_Factor = 1 / (((altitude_feet / 550) × 0.02) + 1)
Adjusted_IBU = IBU × Altitude_Factor
```

### Which Method to Use

- **Tinseth**: Default recommendation. Widely adopted, correlates well with measured IBU.
- **Rager**: Tends to estimate higher for short boil times. Some brewers prefer it for extract brewing.

---

## Color (SRM) Calculations

### Malt Color Units

```
MCU = Σ (lovibond × grain_lbs) / volume_gallons
```

### Morey Formula (Recommended)

```
SRM = 1.4922 × MCU^0.6859
```

Most accurate for the typical MCU range. Non-linear — accounts for diminishing color contribution at higher MCU.

### Daniels Formula

```
MCU > 8:  SRM = 0.2 × MCU + 8.4
MCU ≤ 8:  SRM = 0.3 × MCU + 4.7
```

### Mosher Formula

```
SRM = 0.3 × MCU + 4.7
```

### Color Conversions

```
SRM → EBC:      EBC = SRM × 1.97
EBC → SRM:      SRM = EBC × 0.508
SRM → Lovibond:  L = (SRM + 0.76) / 1.3546
Lovibond → SRM:  SRM = (1.3546 × L) - 0.76
```

### BU:GU Ratio (Balance)

```
BU:GU = IBU / OG_points
```

| Ratio | Character |
| --- | --- |
| < 0.5 | Malty, sweet |
| 0.5–0.8 | Balanced |
| > 0.8 | Hop-forward |
| > 1.2 | Aggressively bitter |

---

## Scaling Recipes

### By Volume

Multiply all ingredients proportionally:

```
New_Amount = Original_Amount × (New_Volume / Original_Volume)
```

Applies to: grains, hops, sugars, finings, spices, fruit. **Does not** apply to yeast (recalculate pitching rate) or water chemistry salts (recalculate for new volume).

### By Efficiency

When your efficiency differs from the recipe's assumed efficiency:

```
New_Grain_lbs = Recipe_Grain_lbs × (Recipe_Efficiency / Your_Efficiency)
```

Only scale base and specialty **grains**. Do not scale sugars, extracts, honey, or fruit — these have fixed extract potential.

### Extract to All-Grain Conversion

```
LME_lbs → Grain_lbs:  grain = LME_lbs × (36 / (base_grain_PPG × efficiency))
DME_lbs → Grain_lbs:  grain = DME_lbs × (44 / (base_grain_PPG × efficiency))
```

Example: 6 lbs LME → grain at 75% efficiency with 37 PPG base malt = 6 × (36 / (37 × 0.75)) = 7.8 lbs.

---

## Mash Calculations

### Strike Water Temperature

```
Strike_Temp = (0.2 / ratio_qt_per_lb) × (target_mash_temp - grain_temp) + target_mash_temp
```

### Infusion Step Volume

```
Water_qt = (Target_Temp - Current_Temp) × (0.2 × grain_lbs + current_water_qt) / (Infusion_Temp - Target_Temp)
```

### Mash Thickness Conversion

```
qt/lb → L/kg:  L_kg = qt_lb × 2.0864
L/kg → qt/lb:  qt_lb = L_kg / 2.0864
```

Typical range: 1.0–1.75 qt/lb (2.1–3.6 L/kg). Thinner mashes favor fermentability; thicker mashes favor body.

---

## Carbonation / Priming

### Residual CO₂ from Fermentation

```
Residual_CO2 = 3.0378 - (0.050062 × beer_temp_F) + (0.00026555 × beer_temp_F²)
```

### Sugar Needed

```
CO2_needed = target_volumes - residual_CO2
Sugar_grams = (CO2_needed × volume_gal × 3.785 × 4) / sugar_factor
```

Sugar factors:
| Sugar | Factor |
| --- | --- |
| Corn sugar (dextrose) | 0.91 |
| Table sugar (sucrose) | 0.88 |
| DME | 0.71 |
| Honey | ~0.78 |

Target volumes by style:
| Style | CO₂ Volumes |
| --- | --- |
| British ales | 1.5–2.0 |
| American ales | 2.2–2.7 |
| Belgian ales | 2.5–3.5 |
| German lagers | 2.4–2.8 |
| Hefeweizen | 3.0–4.0 |
| Saison | 3.0–3.5 |

---

## Water Chemistry Quick Reference

Full water chemistry documentation: `modules/water-chemistry.md`

### Sulfate:Chloride Ratio

| Ratio | Character |
| --- | --- |
| > 5:1 | Strongly hop-forward |
| 2:1 – 5:1 | Hop-forward / crisp |
| 1:1 – 2:1 | Balanced, slightly hop-leaning |
| 0.5:1 – 1:1 | Balanced, slightly malt-leaning |
| < 0.5:1 | Malt-forward / round |

### Residual Alkalinity

```
RA = (HCO₃ / 1.22) - (Ca / 1.4) - (Mg / 1.7)
```

| RA Range | Best For |
| --- | --- |
| < -50 | Very pale lagers, pilsner |
| -50 to 0 | Pale ales, IPAs |
| 0 to 50 | Amber ales, wheat beers |
| 50 to 100 | Brown ales, Märzen |
| 100 to 150 | Stouts, porters |
| > 150 | Very dark beers only |

### Salt Contributions (ppm per gram per gallon)

| Salt | Ca²⁺ | Mg²⁺ | Na⁺ | Cl⁻ | SO₄²⁻ | HCO₃⁻ |
| --- | --- | --- | --- | --- | --- | --- |
| Gypsum (CaSO₄·2H₂O) | 61.5 | — | — | — | 147.4 | — |
| CaCl₂ (dihydrate) | 72.0 | — | — | 127.4 | — | — |
| Epsom (MgSO₄·7H₂O) | — | 26.1 | — | — | 103.0 | — |
| Table salt (NaCl) | — | — | 104.0 | 160.3 | — | — |
| Baking soda (NaHCO₃) | — | — | 72.3 | — | — | 191.9 |
| Chalk (CaCO₃) | 105.8 | — | — | — | — | 158.4* |

*Chalk dissolves poorly in water. Pre-dissolve in acid or add directly to mash.

---

## Yeast Pitching Rate

```
Cells_needed (billions) = pitch_rate × Plato × volume_mL / 1,000,000
```

| Beer Type | Pitch Rate (M cells/mL/°P) |
| --- | --- |
| Ale (standard) | 0.75 |
| Ale (high gravity >1.065) | 1.0 |
| Lager | 1.5 |
| Hybrid/Kölsch | 1.0 |

A standard 11.5g packet of dry yeast contains ~200 billion cells. A liquid yeast pack (White Labs / Wyeast) contains ~100 billion cells at manufacture, declining with age.

---

## Diastatic Power

```
Lintner → WK:  WK = 3.5 × °L - 16
WK → Lintner:  °L = (WK + 16) / 3.5
```

Minimum ~30°L total for full conversion. 2-row base malt: ~140°L. 6-row: ~160°L. Munich: ~40–70°L. Crystal malts: 0°L (pre-converted).

---

## Common Recipe Adjustments

### Increase Body Without Changing OG
- Mash higher (154–158°F instead of 148–152°F)
- Add unfermentable sugars: lactose (0.5–1 lb/5 gal), maltodextrin
- Use less-attenuative yeast
- Add flaked oats or wheat (5–15% of grist)

### Decrease Body Without Changing OG
- Mash lower (146–150°F)
- Replace base malt with simple sugars (up to 10–15%)
- Use more-attenuative yeast
- Add amylase enzyme

### Adjust Bitterness Without Changing Hop Flavor
- Change bittering hop amount (60-min addition)
- Use higher/lower alpha acid hop variety for bittering
- Leave flavor/aroma additions unchanged

### Adjust Hop Flavor/Aroma Without Changing Bitterness
- Modify late additions (0–15 min, whirlpool, dry hop)
- Leave 60-min bittering charge unchanged
- Whirlpool additions at 170°F contribute flavor with minimal IBU

### Make a Beer Drier
- Increase mash efficiency by mashing thinner
- Lower mash temperature
- Add simple sugar (5–10% of fermentables)
- Choose a high-attenuating yeast
- Ensure adequate yeast nutrition and oxygen

### Darken a Beer Without Changing Flavor
- Add Sinamar (dehusked Carafa) or midnight wheat
- Small amounts of Carafa Special III (1–3% of grist)
- These are dehusked/debittered and add color with minimal roast character
