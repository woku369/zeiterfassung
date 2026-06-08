#!/usr/bin/env python3
"""
Water Chemistry Calculator
Salt additions, ion profiles, and residual alkalinity calculations.
Based on Brewer's Friend water chemistry calculator logic and standard brewing chemistry.
"""

import math
from typing import Dict, List, Optional, Tuple

# =============================================================================
# SALT ION CONTRIBUTIONS
# Measured in ppm per gram per gallon of water.
# =============================================================================

SALT_CONTRIBUTIONS = {
    "gypsum": {  # Calcium Sulfate (CaSO₄·2H₂O)
        "name": "Gypsum",
        "formula": "CaSO₄·2H₂O",
        "Ca": 61.5,
        "SO4": 147.4,
    },
    "calcium_chloride": {  # Calcium Chloride dihydrate (CaCl₂·2H₂O)
        "name": "Calcium Chloride (dihydrate)",
        "formula": "CaCl₂·2H₂O",
        "Ca": 72.0,
        "Cl": 127.4,
    },
    "calcium_chloride_anhydrous": {  # Calcium Chloride anhydrous (CaCl₂)
        "name": "Calcium Chloride (anhydrous)",
        "formula": "CaCl₂",
        "Ca": 95.2,
        "Cl": 168.5,
    },
    "epsom": {  # Magnesium Sulfate (MgSO₄·7H₂O)
        "name": "Epsom Salt",
        "formula": "MgSO₄·7H₂O",
        "Mg": 26.1,
        "SO4": 103.0,
    },
    "table_salt": {  # Sodium Chloride (NaCl)
        "name": "Table Salt (non-iodized)",
        "formula": "NaCl",
        "Na": 104.0,
        "Cl": 160.3,
    },
    "baking_soda": {  # Sodium Bicarbonate (NaHCO₃)
        "name": "Baking Soda",
        "formula": "NaHCO₃",
        "Na": 72.3,
        "HCO3": 191.9,
    },
    "chalk": {  # Calcium Carbonate (CaCO₃)
        "name": "Chalk",
        "formula": "CaCO₃",
        "Ca": 105.8,
        "CO3": 158.4,
    },
    "slaked_lime": {  # Calcium Hydroxide (Ca(OH)₂)
        "name": "Slaked Lime",
        "formula": "Ca(OH)₂",
        "Ca": 142.8,
        "OH": 114.6,
    },
    "magnesium_chloride": {  # Magnesium Chloride (MgCl₂·6H₂O)
        "name": "Magnesium Chloride",
        "formula": "MgCl₂·6H₂O",
        "Mg": 31.6,
        "Cl": 92.2,
    },
}


# =============================================================================
# CLASSIC WATER PROFILES (ppm)
# From Brewer's Friend and standard brewing references.
# =============================================================================

WATER_PROFILES = {
    "distilled": {
        "name": "Distilled / RO",
        "Ca": 0, "Mg": 0, "Na": 0, "Cl": 0, "SO4": 0, "HCO3": 0,
    },
    "burton": {
        "name": "Burton-on-Trent",
        "Ca": 295, "Mg": 45, "Na": 55, "Cl": 25, "SO4": 725, "HCO3": 300,
    },
    "dublin": {
        "name": "Dublin",
        "Ca": 120, "Mg": 4, "Na": 12, "Cl": 19, "SO4": 54, "HCO3": 315,
    },
    "london": {
        "name": "London",
        "Ca": 70, "Mg": 6, "Na": 15, "Cl": 38, "SO4": 40, "HCO3": 166,
    },
    "munich": {
        "name": "Munich",
        "Ca": 77, "Mg": 18, "Na": 2, "Cl": 2, "SO4": 10, "HCO3": 295,
    },
    "pilsen": {
        "name": "Pilsen",
        "Ca": 7, "Mg": 2, "Na": 2, "Cl": 5, "SO4": 5, "HCO3": 25,
    },
    "vienna": {
        "name": "Vienna",
        "Ca": 200, "Mg": 60, "Na": 8, "Cl": 12, "SO4": 125, "HCO3": 120,
    },
    "dortmund": {
        "name": "Dortmund",
        "Ca": 225, "Mg": 40, "Na": 60, "Cl": 60, "SO4": 220, "HCO3": 180,
    },
    "edinburgh": {
        "name": "Edinburgh",
        "Ca": 125, "Mg": 25, "Na": 55, "Cl": 65, "SO4": 140, "HCO3": 225,
    },
    "yellow_balanced": {
        "name": "Light & Balanced (BF Yellow Balanced)",
        "Ca": 40, "Mg": 5, "Na": 20, "Cl": 40, "SO4": 30, "HCO3": 40,
        "descr": "Low RA, balanced SO4:Cl. Good for pale, malt-forward beers (2-5 SRM).",
    },
    "yellow_hoppy": {
        "name": "Light & Hoppy (BF Yellow Hoppy)",
        "Ca": 40, "Mg": 5, "Na": 20, "Cl": 20, "SO4": 60, "HCO3": 40,
        "descr": "Low RA, SO4-forward. Good for pale, hop-forward beers (2-5 SRM).",
    },
}


# =============================================================================
# STYLE-BASED WATER GUIDELINES
# =============================================================================

STYLE_WATER_RANGES = {
    "pale_hoppy": {
        "name": "Pale & Hoppy (IPA, Pale Ale)",
        "Ca": (50, 150), "Mg": (0, 30), "Na": (0, 30),
        "Cl": (0, 50), "SO4": (100, 300), "HCO3": (0, 50),
        "sulfate_chloride_ratio": "2:1 to 5:1",
    },
    "pale_balanced": {
        "name": "Pale & Balanced (Kölsch, Blonde, Cream Ale)",
        "Ca": (40, 100), "Mg": (0, 20), "Na": (0, 30),
        "Cl": (30, 70), "SO4": (30, 70), "HCO3": (0, 75),
        "sulfate_chloride_ratio": "~1:1",
    },
    "amber_malty": {
        "name": "Amber & Malty (Märzen, Oktoberfest, Brown Ale)",
        "Ca": (50, 120), "Mg": (5, 25), "Na": (0, 40),
        "Cl": (40, 80), "SO4": (30, 80), "HCO3": (50, 150),
        "sulfate_chloride_ratio": "0.5:1 to 1:1",
    },
    "dark_roasty": {
        "name": "Dark & Roasty (Stout, Porter)",
        "Ca": (50, 150), "Mg": (5, 30), "Na": (0, 50),
        "Cl": (50, 100), "SO4": (30, 80), "HCO3": (100, 300),
        "sulfate_chloride_ratio": "0.5:1 to 1:1",
    },
    "pilsner": {
        "name": "Pilsner / Light Lager",
        "Ca": (5, 50), "Mg": (0, 10), "Na": (0, 10),
        "Cl": (0, 30), "SO4": (0, 50), "HCO3": (0, 50),
        "sulfate_chloride_ratio": "varies",
    },
}


# =============================================================================
# ION CALCULATION FUNCTIONS
# =============================================================================

def calculate_salt_additions(salts_grams: Dict[str, float],
                             volume_gallons: float) -> Dict[str, float]:
    """
    Calculate ion contributions from salt additions.

    Args:
        salts_grams: Dict of {salt_key: grams} (keys from SALT_CONTRIBUTIONS)
        volume_gallons: Water volume in gallons

    Returns:
        Dict of ion concentrations in ppm: {Ca, Mg, Na, Cl, SO4, HCO3}
    """
    ions = {"Ca": 0, "Mg": 0, "Na": 0, "Cl": 0, "SO4": 0, "HCO3": 0, "CO3": 0, "OH": 0}

    for salt_key, grams in salts_grams.items():
        if salt_key not in SALT_CONTRIBUTIONS:
            continue

        salt = SALT_CONTRIBUTIONS[salt_key]

        for ion in ions:
            if ion in salt:
                # ppm = (grams / volume_gallons) * contribution_per_gram_per_gallon
                ions[ion] += (grams / volume_gallons) * salt[ion]

    # Round all values
    return {ion: round(ppm, 1) for ion, ppm in ions.items()}


def combined_water_profile(base_profile: Dict[str, float],
                           salts_grams: Dict[str, float],
                           volume_gallons: float) -> Dict[str, float]:
    """
    Calculate final water profile from base water + salt additions.

    Args:
        base_profile: Base water ion levels in ppm (Ca, Mg, Na, Cl, SO4, HCO3)
        salts_grams: Salt additions in grams
        volume_gallons: Water volume in gallons

    Returns:
        Final ion profile in ppm
    """
    salt_ions = calculate_salt_additions(salts_grams, volume_gallons)

    result = {}
    for ion in ["Ca", "Mg", "Na", "Cl", "SO4", "HCO3"]:
        base = base_profile.get(ion, 0)
        added = salt_ions.get(ion, 0)
        result[ion] = round(base + added, 1)

    return result


def dilute_water(source_profile: Dict[str, float],
                 source_volume: float,
                 dilution_volume: float) -> Dict[str, float]:
    """
    Calculate diluted water profile (e.g., blending tap water with RO/distilled).

    Args:
        source_profile: Source water ion levels in ppm
        source_volume: Volume of source water
        dilution_volume: Volume of RO/distilled water to add

    Returns:
        Diluted ion profile in ppm
    """
    total_volume = source_volume + dilution_volume
    if total_volume <= 0:
        return {ion: 0 for ion in source_profile}

    ratio = source_volume / total_volume
    return {ion: round(ppm * ratio, 1) for ion, ppm in source_profile.items()}


# =============================================================================
# RESIDUAL ALKALINITY
# =============================================================================

def residual_alkalinity(ca_ppm: float, mg_ppm: float,
                        hco3_ppm: float) -> float:
    """
    Calculate Residual Alkalinity (RA) using Kolbach formula.
    RA = Alkalinity - (Ca/1.4) - (Mg/1.7)

    Where Alkalinity ≈ HCO3 / 1.22 (converted to ppm as CaCO3)

    Args:
        ca_ppm: Calcium in ppm
        mg_ppm: Magnesium in ppm
        hco3_ppm: Bicarbonate in ppm

    Returns:
        Residual alkalinity in ppm as CaCO3
    """
    alkalinity_as_caco3 = hco3_ppm / 1.22
    ra = alkalinity_as_caco3 - (ca_ppm / 1.4) - (mg_ppm / 1.7)
    return round(ra, 1)


def effective_alkalinity(hco3_ppm: float) -> float:
    """
    Calculate effective alkalinity as ppm CaCO3.
    Alkalinity (as CaCO3) ≈ HCO3 / 1.22
    """
    return round(hco3_ppm / 1.22, 1)


def estimated_mash_ph(ra: float, grain_color_srm: float = 4.0) -> float:
    """
    Rough estimate of mash pH based on residual alkalinity and grain bill color.
    This is a simplified approximation. Real mash pH depends on many factors
    including grain buffering capacity, mash thickness, and temperature.

    For a typical all-grain mash:
    - Base malt alone in distilled water: ~5.7-5.8 pH
    - Each 50 ppm RA raises pH by ~0.1
    - Darker malts lower pH

    Args:
        ra: Residual alkalinity in ppm as CaCO3
        grain_color_srm: Average SRM of grain bill

    Returns:
        Estimated mash pH (approximate)
    """
    base_ph = 5.72  # Base malt in distilled water

    # RA contribution (~0.1 pH per 50 ppm RA)
    ra_adjustment = ra * 0.002

    # Grain color adjustment (darker grains lower pH)
    # Very rough: each 10 SRM above base malt lowers pH by ~0.05
    color_adjustment = -((grain_color_srm - 3) * 0.005) if grain_color_srm > 3 else 0

    estimated = base_ph + ra_adjustment + color_adjustment

    return round(min(max(estimated, 4.5), 6.5), 2)


# =============================================================================
# SULFATE:CHLORIDE RATIO
# =============================================================================

def sulfate_chloride_ratio(so4_ppm: float, cl_ppm: float) -> Tuple[float, str]:
    """
    Calculate sulfate-to-chloride ratio and interpret flavor balance.

    Returns:
        Tuple of (ratio, description)
    """
    if cl_ppm <= 0:
        return (float('inf'), "All sulfate, no chloride — extreme hop-forward")

    ratio = so4_ppm / cl_ppm

    if ratio > 9:
        desc = "Very hop-forward, potentially harsh"
    elif ratio > 5:
        desc = "Strongly hop-forward"
    elif ratio >= 2:
        desc = "Hop-forward / crisp bitterness"
    elif ratio >= 1:
        desc = "Balanced, slightly hop-leaning"
    elif ratio >= 0.5:
        desc = "Balanced, slightly malt-leaning"
    elif ratio >= 0.2:
        desc = "Malt-forward / round, full flavor"
    else:
        desc = "Very malt-forward, potentially minerally"

    return (round(ratio, 2), desc)


# =============================================================================
# BUILDING WATER FROM RO
# =============================================================================

def build_water_profile(target_profile: Dict[str, float],
                        volume_gallons: float) -> Dict[str, float]:
    """
    Calculate approximate salt additions to build a target water profile from RO water.
    Uses a simplified approach: gypsum for Ca+SO4, CaCl2 for Ca+Cl, epsom for Mg+SO4,
    table salt for Na+Cl, baking soda for Na+HCO3.

    This provides a starting point. Real water building requires iterative adjustment.

    Args:
        target_profile: Target ion levels in ppm (Ca, Mg, Na, Cl, SO4, HCO3)
        volume_gallons: Water volume in gallons

    Returns:
        Dict of salt additions in grams
    """
    target_ca = target_profile.get("Ca", 0)
    target_mg = target_profile.get("Mg", 0)
    target_na = target_profile.get("Na", 0)
    target_cl = target_profile.get("Cl", 0)
    target_so4 = target_profile.get("SO4", 0)
    target_hco3 = target_profile.get("HCO3", 0)

    salts = {}

    # Baking soda for bicarbonate (adds Na and HCO3)
    if target_hco3 > 0:
        baking_soda_g = (target_hco3 * volume_gallons) / SALT_CONTRIBUTIONS["baking_soda"]["HCO3"]
        salts["baking_soda"] = baking_soda_g
        na_from_baking = baking_soda_g / volume_gallons * SALT_CONTRIBUTIONS["baking_soda"]["Na"]
        target_na = max(0, target_na - na_from_baking)

    # Epsom salt for Mg (adds Mg and SO4)
    if target_mg > 0:
        epsom_g = (target_mg * volume_gallons) / SALT_CONTRIBUTIONS["epsom"]["Mg"]
        salts["epsom"] = epsom_g
        so4_from_epsom = epsom_g / volume_gallons * SALT_CONTRIBUTIONS["epsom"]["SO4"]
        target_so4 = max(0, target_so4 - so4_from_epsom)

    # Gypsum for remaining SO4 (adds Ca and SO4)
    if target_so4 > 0:
        gypsum_g = (target_so4 * volume_gallons) / SALT_CONTRIBUTIONS["gypsum"]["SO4"]
        salts["gypsum"] = gypsum_g
        ca_from_gypsum = gypsum_g / volume_gallons * SALT_CONTRIBUTIONS["gypsum"]["Ca"]
        target_ca = max(0, target_ca - ca_from_gypsum)

    # CaCl2 for remaining Ca (adds Ca and Cl)
    if target_ca > 0:
        cacl2_g = (target_ca * volume_gallons) / SALT_CONTRIBUTIONS["calcium_chloride"]["Ca"]
        salts["calcium_chloride"] = cacl2_g
        cl_from_cacl2 = cacl2_g / volume_gallons * SALT_CONTRIBUTIONS["calcium_chloride"]["Cl"]
        target_cl = max(0, target_cl - cl_from_cacl2)

    # Table salt for remaining Cl and Na
    if target_cl > 0:
        nacl_g = (target_cl * volume_gallons) / SALT_CONTRIBUTIONS["table_salt"]["Cl"]
        salts["table_salt"] = nacl_g

    # Round and remove zeros
    return {k: round(v, 2) for k, v in salts.items() if v > 0.01}


# =============================================================================
# ACID ADDITIONS
# =============================================================================

ACID_PROPERTIES = {
    "lactic_88": {
        "name": "Lactic Acid (88%)",
        "strength": 0.88,
        "meq_per_ml": 10.78,
    },
    "phosphoric_10": {
        "name": "Phosphoric Acid (10%)",
        "strength": 0.10,
        "meq_per_ml": 1.53,
    },
    "phosphoric_85": {
        "name": "Phosphoric Acid (85%)",
        "strength": 0.85,
        "meq_per_ml": 13.05,
    },
    "hydrochloric_10": {
        "name": "Hydrochloric Acid (10%)",
        "strength": 0.10,
        "meq_per_ml": 2.87,
    },
    "citric": {
        "name": "Citric Acid (powder)",
        "meq_per_gram": 15.6,
    },
    "acidulated_malt": {
        "name": "Acidulated Malt (2% lactic)",
        "ph_drop_per_percent": 0.1,  # ~0.1 pH per 1% of grain bill
    },
}


def acid_for_ph_reduction(current_hco3_ppm: float, target_ph_drop: float,
                          volume_gallons: float,
                          acid_type: str = "lactic_88") -> float:
    """
    Approximate acid volume needed to reduce water alkalinity.
    This is a rough estimate — always verify with a pH meter.

    Args:
        current_hco3_ppm: Current bicarbonate level
        target_ph_drop: Desired pH reduction (e.g., 0.3)
        volume_gallons: Water volume
        acid_type: Key from ACID_PROPERTIES

    Returns:
        mL of acid (or grams for powder)
    """
    # Simplified: ~50 ppm HCO3 reduction per 0.1 pH drop
    hco3_reduction = target_ph_drop * 500
    meq_needed = (hco3_reduction * volume_gallons * 3.785) / 61

    acid = ACID_PROPERTIES.get(acid_type)
    if not acid:
        return 0

    if "meq_per_ml" in acid:
        return round(meq_needed / acid["meq_per_ml"], 1)
    elif "meq_per_gram" in acid:
        return round(meq_needed / acid["meq_per_gram"], 1)
    return 0


# =============================================================================
# DISPLAY / ANALYSIS
# =============================================================================

def analyze_water(profile: Dict[str, float]) -> Dict:
    """
    Analyze a water profile and provide brewing recommendations.
    """
    ca = profile.get("Ca", 0)
    mg = profile.get("Mg", 0)
    na = profile.get("Na", 0)
    cl = profile.get("Cl", 0)
    so4 = profile.get("SO4", 0)
    hco3 = profile.get("HCO3", 0)

    ra = residual_alkalinity(ca, mg, hco3)
    alk = effective_alkalinity(hco3)
    ratio, ratio_desc = sulfate_chloride_ratio(so4, cl)

    # Ion warnings
    warnings = []
    if ca < 40:
        warnings.append("Ca below 40 ppm — may impair yeast health and enzyme activity")
    if ca > 200:
        warnings.append("Ca above 200 ppm — may produce harsh minerally character")
    if na > 150:
        warnings.append("Na above 150 ppm — may taste salty/sour")
    if so4 > 400:
        warnings.append("SO₄ above 400 ppm — may produce harsh/astringent bitterness")
    if cl > 200:
        warnings.append("Cl above 200 ppm — may stress yeast and produce medicinal flavors")
    if mg > 40:
        warnings.append("Mg above 40 ppm — may produce sour/bitter flavors")

    # Style recommendations
    recommendations = []
    if ra < -50:
        recommendations.append("Very soft, acidic water — ideal for very pale, delicate lagers")
    elif ra < 0:
        recommendations.append("Good for pale ales, IPAs, pilsners")
    elif ra < 50:
        recommendations.append("Good for amber ales, pale lagers, wheat beers")
    elif ra < 100:
        recommendations.append("Good for amber/brown ales, Märzen, Vienna lager")
    elif ra < 150:
        recommendations.append("Good for dark ales, stouts, porters")
    else:
        recommendations.append("Very high RA — best for very dark beers or consider acid treatment")

    return {
        "profile": profile,
        "residual_alkalinity": ra,
        "effective_alkalinity": alk,
        "sulfate_chloride_ratio": ratio,
        "sulfate_chloride_description": ratio_desc,
        "estimated_pale_malt_mash_ph": estimated_mash_ph(ra, 4.0),
        "warnings": warnings,
        "recommendations": recommendations,
    }


def print_water_analysis(profile: Dict[str, float], name: str = "Water"):
    """Print a formatted water analysis."""
    analysis = analyze_water(profile)

    print(f"\n=== {name} Analysis ===")
    print(f"  Ca: {profile.get('Ca', 0)} | Mg: {profile.get('Mg', 0)} | Na: {profile.get('Na', 0)}")
    print(f"  Cl: {profile.get('Cl', 0)} | SO₄: {profile.get('SO4', 0)} | HCO₃: {profile.get('HCO3', 0)}")
    print(f"  Residual Alkalinity: {analysis['residual_alkalinity']} ppm as CaCO₃")
    print(f"  SO₄:Cl ratio: {analysis['sulfate_chloride_ratio']} ({analysis['sulfate_chloride_description']})")
    print(f"  Est. mash pH (base malt): {analysis['estimated_pale_malt_mash_ph']}")

    if analysis['warnings']:
        print("  Warnings:")
        for w in analysis['warnings']:
            print(f"    ⚠ {w}")

    if analysis['recommendations']:
        print("  Suited for:")
        for r in analysis['recommendations']:
            print(f"    → {r}")


if __name__ == "__main__":
    print("=== Water Chemistry Calculator Examples ===")

    # Analyze Burton-on-Trent water
    burton = WATER_PROFILES["burton"]
    print_water_analysis(burton, burton["name"])

    # Analyze Pilsen water
    pilsen = WATER_PROFILES["pilsen"]
    print_water_analysis(pilsen, pilsen["name"])

    print("\n--- Building IPA water from RO ---")
    target = {"Ca": 100, "Mg": 10, "Na": 15, "Cl": 50, "SO4": 200, "HCO3": 0}
    additions = build_water_profile(target, 5.0)

    print(f"  Target: Ca={target['Ca']} Mg={target['Mg']} Na={target['Na']} "
          f"Cl={target['Cl']} SO₄={target['SO4']} HCO₃={target['HCO3']}")
    print("  Salt additions for 5 gallons:")
    for salt, grams in additions.items():
        info = SALT_CONTRIBUTIONS[salt]
        print(f"    {info['name']}: {grams}g")

    # Verify result
    result = combined_water_profile({"Ca": 0, "Mg": 0, "Na": 0, "Cl": 0, "SO4": 0, "HCO3": 0},
                                     additions, 5.0)
    print(f"  Result: Ca={result['Ca']} Mg={result['Mg']} Na={result['Na']} "
          f"Cl={result['Cl']} SO₄={result['SO4']} HCO₃={result['HCO3']}")
    print_water_analysis(result, "Built IPA Water")

    print("\n--- Salt addition example ---")
    print("  Adding 3g gypsum + 2g CaCl2 to 5 gal Pilsen water:")
    adjusted = combined_water_profile(
        WATER_PROFILES["pilsen"],
        {"gypsum": 3, "calcium_chloride": 2},
        5.0
    )
    print(f"  Result: Ca={adjusted['Ca']} Mg={adjusted['Mg']} Na={adjusted['Na']} "
          f"Cl={adjusted['Cl']} SO₄={adjusted['SO4']} HCO₃={adjusted['HCO3']}")
    print_water_analysis(adjusted, "Adjusted Pilsen")
