# Refractometer Corrections Guide

Refractometers measure the refractive index of a liquid, which correlates with dissolved solids (sugars). However, several factors require correction for accurate readings in fermentation contexts.

## The Problem

Refractometers are calibrated for pure sucrose solutions. Wort, wine must, and mead have different compositions that affect light refraction differently. Additionally, once alcohol is present (during/after fermentation), readings become significantly skewed because ethanol has a higher refractive index than water.

---

## Wort Correction Factor (WCF)

### Why It's Needed

Wort contains proteins, dextrins, and other compounds beyond simple sugars. These affect refraction differently than pure sucrose, causing most refractometers to read slightly high.

### Typical Values

| Correction Factor | Notes |
|-------------------|-------|
| 1.00 | No correction (rare) |
| 1.02-1.04 | Common range for most refractometers |
| 1.04 | Default value used by most calculators |
| 1.06 | High end of typical range |

### How to Determine Your WCF

1. **Calibrate** refractometer with distilled water at 68°F (20°C) to read 0.0 Brix
2. **Prepare test wort** (any unfermented wort works)
3. **Measure with refractometer** — record as "Brix WRI" (wort refraction index)
4. **Measure with hydrometer** — ensure temperature correction, record actual SG
5. **Convert hydrometer SG to Brix**: `Brix = (SG - 1) / 0.004`
6. **Calculate WCF**: `WCF = Refractometer Brix / Hydrometer Brix`
7. **Repeat** across 10-30 different worts and average results

**Example:**
- Refractometer reads: 14.5 Brix
- Hydrometer reads: 1.056 SG = 14.0 Brix
- WCF = 14.5 / 14.0 = 1.036

### Applying the Correction

```
Actual Brix = Measured Brix / WCF
Actual SG = 1 + (Actual Brix × 0.004)
```

---

## Alcohol Correction (During/Post-Fermentation)

### Why It's Needed

Ethanol has a refractive index of 1.361 (vs. water at 1.333). As alcohol increases, refractometer readings are thrown off—a dry wine may read 5-15 Brix despite having minimal residual sugar.

### Sean Terrill Formula (Recommended)

The most widely-used correction for final gravity:

```
FG = 1.0000 − 0.0044993×OBrix + 0.011774×FBrix + 0.00027581×OBrix²
     − 0.0012717×FBrix² − 0.0000072800×OBrix³ + 0.000063293×FBrix³
```

Where:
- OBrix = Original Brix reading (pre-fermentation)
- FBrix = Final Brix reading (current/post-fermentation)

**Accuracy:** ±1-2 gravity points in most cases

### Novotný Linear Formula (Simpler)

```
FG = 1.001843 − 0.002318474×OB − 0.000007775×OB² − 0.000000034×OB³
     + 0.00574×CB + 0.00003344×CB² + 0.000000086×CB³
```

Where OB = Original Brix, CB = Current Brix

### ABV from Dual Readings

If you have both hydrometer SG and refractometer Brix on fermenting/finished product:

```
ABV = 1.646 × Brix − 2.703 × (145 − 145/SG) − 1.794
```

---

## Beverage-Specific Considerations

### Beer Wort

- Standard WCF of 1.04 works well for most styles
- Highly hopped worts may read slightly different
- Crystal/caramel-heavy worts may need individual calibration
- **Best practice:** Determine your system's WCF empirically

### Wine Must

- Grape must reads close to pure sucrose—minimal correction needed
- Some winemakers use WCF of 0.99-1.00
- High-acid musts may read slightly lower
- **Caution:** Post-fermentation readings highly inaccurate without correction

### Mead Must

Mead presents unique challenges:

| Challenge | Impact |
|-----------|--------|
| High starting gravity (1.090-1.130+) | Exceeds calibration range of many refractometers |
| Variable honey composition | Different honeys have different non-sugar solids |
| High final ABV (>10%) | Larger alcohol correction needed |
| Residual honey post-fermentation | Complex sugar profile affects readings |

**Recommendations for mead:**
1. Use refractometer only for pre-fermentation OG
2. Rely on hydrometer for all FG readings
3. If using refractometer during fermentation, treat as trend indicator only
4. Verify correction accuracy with parallel hydrometer readings

### Cider

- Similar to wine—apple juice is mostly simple sugars
- WCF typically 1.00-1.02
- Post-fermentation corrections work reasonably well

---

## Online Calculators

| Calculator | URL | Notes |
|------------|-----|-------|
| Brewer's Friend | [brewersfriend.com/refractometer-calculator](https://www.brewersfriend.com/refractometer-calculator/) | Terrill and standard formulas |
| Northern Brewer | [northernbrewer.com/pages/refractometer-calculator](https://www.northernbrewer.com/pages/refractometer-calculator) | Pre/post fermentation |
| Vinolab | [vinolab.hr/calculator](https://www.vinolab.hr/calculator/en4) | Wine-focused |
| FermCalc | [fermcalc.com](https://fermcalc.com/hydrometer-refractometer/) | Rogerson-Symington method |
| Sean Terrill | [seanterrill.com](http://seanterrill.com/2011/04/01/refractometer-fg-results/) | Original research/spreadsheet |

---

## Best Practices

### Pre-Fermentation
1. Always calibrate with distilled water before use
2. Let sample cool to room temperature (or use ATC refractometer)
3. Apply your determined WCF to raw readings
4. Record both raw and corrected values

### During Fermentation
1. Use refractometer as trend indicator, not absolute measurement
2. Record OG Brix for later correction calculations
3. Expect readings to decrease more slowly than actual gravity drop
4. Take parallel hydrometer readings at key points

### Post-Fermentation
1. **Always verify FG with hydrometer** before packaging
2. Use correction calculators for refractometer FG estimates
3. Remember: dry ferments may still read 5-10+ Brix
4. For high-ABV beverages (>12%), hydrometer is essential

### When NOT to Trust Refractometer

- Final gravity determination (use hydrometer)
- High-gravity ferments (>1.100 OG)
- Meads with residual honey
- Any reading where packaging decision depends on accuracy
- If reading seems inconsistent with fermentation behavior

---

## Quick Reference Card

### Brix to SG Conversion (Pre-Fermentation)

| Brix | SG |
|------|-----|
| 10 | 1.040 |
| 12 | 1.048 |
| 14 | 1.056 |
| 16 | 1.065 |
| 18 | 1.074 |
| 20 | 1.083 |
| 22 | 1.092 |
| 24 | 1.101 |

**Formula:** `SG = 1 + (Brix × 0.004)` (approximate)

**More accurate:** `SG = 1 + (Brix / (258.6 - 0.8796 × Brix))`

### Temperature Correction

Most refractometers are calibrated at 68°F (20°C). ATC (automatic temperature compensation) models adjust automatically within a range (typically 50-86°F).

For non-ATC units, add approximately +0.03 Brix per 1°F above 68°F.

---

## Sources

- [Brewer's Friend: Wort Correction Factor](https://www.brewersfriend.com/how-to-determine-your-refractometers-wort-correction-factor/)
- [Brewer's Friend: Refractometer Calculator](https://www.brewersfriend.com/refractometer-calculator/)
- [BYO: Understanding Refractometers](https://byo.com/article/refractometers/)
- [Sean Terrill: Refractometer FG Research](http://seanterrill.com/2011/04/01/refractometer-fg-results/)
- [Vinolab: Wine Fermentation Monitoring](https://www.vinolab.hr/calculator/monitor-ferment-from-refractometer-readings-en28)
- [FermCalc: Rogerson-Symington Method](https://fermcalc.com/hydrometer-refractometer/)
