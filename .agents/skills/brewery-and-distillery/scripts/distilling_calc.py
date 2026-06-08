#!/usr/bin/env python3
"""
Distilling Calculator Library
Formulas for wash preparation, distillation, dilution, proofing, blending,
yield estimation, column design, and equipment sizing.

Sources:
  - American Home Distillers Association (americanhomedistillers.com)
  - PhilBilly Moonshine (philbillymoonshine.com)
  - Homedistiller.org wiki
  - Clawhammer Supply potential alcohol tables
  - TTB Gauging Manual principles
"""

import math
from typing import Dict, List, Optional, Tuple, Union


# =============================================================================
# CONSTANTS
# =============================================================================

# Sugar fermentation chemistry
SUGAR_TO_ETHANOL_THEORETICAL = 0.511   # 51.1% by weight (Gay-Lussac)
SUGAR_TO_ETHANOL_PRACTICAL = 0.48      # ~48% accounting for byproducts
SUGAR_TO_CO2_THEORETICAL = 0.489       # 48.9% by weight

# Ethanol properties
ETHANOL_DENSITY_KG_L = 0.789           # kg/L at 20°C
ETHANOL_BOILING_POINT_F = 173.1        # °F
ETHANOL_BOILING_POINT_C = 78.37        # °C
WATER_BOILING_POINT_F = 212.0
WATER_BOILING_POINT_C = 100.0

# Practical yield factors
FERMENTATION_EFFICIENCY = 0.90         # ~90% of theoretical
DISTILLATION_COLLECTION_EFF = 0.85     # typical home still ~85%

# Unit conversions
LBS_PER_GALLON = 8.33
GRAMS_PER_LB = 453.59237
LITERS_PER_GALLON = 3.78541
ML_PER_GALLON = 3785.41

# Specific heat of water (cal/g/°C)
SPECIFIC_HEAT_WATER = 1.0
# Watt-second to calorie
WATTS_TO_CAL_PER_SEC = 0.238846


# =============================================================================
# ABV, PROOF, AND GRAVITY
# =============================================================================

def abv_to_proof(abv: float) -> float:
    """Convert ABV percentage to US proof (proof = 2 × ABV)."""
    return round(abv * 2, 1)


def proof_to_abv(proof: float) -> float:
    """Convert US proof to ABV percentage."""
    return round(proof / 2, 1)


def abv_from_gravity(og: float, fg: float) -> float:
    """
    Calculate ABV from original and final specific gravity.
    Standard formula: ABV = (OG - FG) × 131.25
    """
    return round((og - fg) * 131.25, 2)


def abv_from_gravity_alternate(og: float, fg: float) -> float:
    """
    Calculate ABV using alternate formula (more accurate for high-gravity washes).
    ABV = 76.08 × (OG - FG) / (1.775 - OG) × (FG / 0.794)
    """
    abv = 76.08 * (og - fg) / (1.775 - og)
    abv = abv * (fg / 0.794)
    return round(abv, 2)


def gravity_to_plato(gravity: float) -> float:
    """Convert specific gravity to degrees Plato."""
    return round((-616.868) + (1111.14 * gravity) -
                 (630.272 * gravity**2) + (135.997 * gravity**3), 1)


def plato_to_gravity(plato: float) -> float:
    """Convert degrees Plato to specific gravity."""
    return round((plato / (258.6 - ((plato / 258.2) * 227.1))) + 1, 4)


def gravity_points(gravity: float) -> float:
    """Extract gravity points (e.g., 1.080 → 80)."""
    return round((gravity - 1) * 1000, 1)


# =============================================================================
# SUGAR WASH CALCULATIONS
# =============================================================================

def sugar_for_target_abv(volume_gallons: float, target_abv: float) -> Dict[str, float]:
    """
    Calculate sugar needed for a target ABV in a sugar wash.

    Rule of thumb: 1 lb sugar per gallon ≈ 5.9% ABV.
    More precisely: Volume(L) × target_ABV% × 17g = sugar grams needed.

    Args:
        volume_gallons: Total wash volume in gallons
        target_abv: Target alcohol percentage (e.g., 10 for 10%)

    Returns:
        Dict with sugar amounts in lbs and kg, expected OG
    """
    volume_liters = volume_gallons * LITERS_PER_GALLON

    # Formula: sugar_grams = volume_L × ABV% × 17
    sugar_grams = volume_liters * target_abv * 17
    sugar_lbs = sugar_grams / GRAMS_PER_LB
    sugar_kg = sugar_grams / 1000

    # Estimate OG from sugar addition
    # ~46 PPG for pure sugar, dissolved in total volume
    og_points = (sugar_lbs * 46) / volume_gallons
    estimated_og = 1 + (og_points / 1000)

    return {
        "sugar_lbs": round(sugar_lbs, 2),
        "sugar_kg": round(sugar_kg, 2),
        "sugar_grams": round(sugar_grams, 0),
        "estimated_og": round(estimated_og, 3),
        "target_abv": target_abv,
        "volume_gallons": volume_gallons,
    }


def sugar_wash_og(sugar_lbs: float, volume_gallons: float) -> Dict[str, float]:
    """
    Calculate the OG and potential ABV of a sugar wash.

    Args:
        sugar_lbs: Pounds of sugar
        volume_gallons: Total wash volume in gallons

    Returns:
        Dict with OG, potential ABV, gravity points
    """
    # Sugar PPG ≈ 46
    points = (sugar_lbs * 46) / volume_gallons
    og = 1 + (points / 1000)

    # Potential ABV assuming complete fermentation to ~1.000
    potential_abv = points * 131.25 / 1000

    return {
        "og": round(og, 3),
        "gravity_points": round(points, 1),
        "potential_abv": round(potential_abv, 1),
        "sugar_lbs": sugar_lbs,
        "volume_gallons": volume_gallons,
    }


def grain_mash_og(grain_lbs: float, ppg: float, volume_gallons: float,
                   efficiency: float = 0.65) -> Dict[str, float]:
    """
    Calculate OG and potential ABV of a grain mash.

    Args:
        grain_lbs: Total grain weight in pounds
        ppg: Points per pound per gallon of grain (e.g., 37 for 2-row)
        volume_gallons: Total mash volume in gallons
        efficiency: Mash efficiency (0.55-0.80 typical for distilling)

    Returns:
        Dict with OG, potential ABV
    """
    points = (grain_lbs * ppg * efficiency) / volume_gallons
    og = 1 + (points / 1000)
    potential_abv = points * 131.25 / 1000

    return {
        "og": round(og, 3),
        "gravity_points": round(points, 1),
        "potential_abv": round(potential_abv, 1),
        "grain_lbs": grain_lbs,
        "efficiency_pct": round(efficiency * 100, 1),
    }


def predicted_spirit_yield(fermentable_extract: float,
                            malt_weight_tonnes: float = 1.0) -> Dict[str, float]:
    """
    Calculate Predicted Spirit Yield (PSY) using the Dolan factor.

    PSY (litres of absolute alcohol per tonne) = fermentable_extract × 6.06

    Args:
        fermentable_extract: Fermentable extract in liters per kilogram
                            (extract × fermentability / 100)
        malt_weight_tonnes: Weight of malt in metric tonnes

    Returns:
        Dict with PSY and total alcohol volume
    """
    psy = fermentable_extract * 6.06  # Dolan factor
    total_alcohol_liters = psy * malt_weight_tonnes

    return {
        "psy_laa_per_tonne": round(psy, 1),
        "total_alcohol_liters": round(total_alcohol_liters, 1),
        "malt_weight_tonnes": malt_weight_tonnes,
    }


# =============================================================================
# DISTILLATE YIELD
# =============================================================================

def distillate_yield_from_wash(wash_volume_gallons: float,
                                wash_abv: float,
                                collection_abv: float = 65.0,
                                collection_efficiency: float = 0.85) -> Dict[str, float]:
    """
    Estimate distillate output from a wash.

    Args:
        wash_volume_gallons: Volume of wash in gallons
        wash_abv: ABV of the wash (e.g., 10 for 10%)
        collection_abv: Average ABV of collected distillate (e.g., 65%)
        collection_efficiency: Fraction of alcohol recovered (0.80-0.90 typical)

    Returns:
        Dict with alcohol volumes and distillate amounts
    """
    # Total alcohol in wash
    alcohol_volume_gal = wash_volume_gallons * (wash_abv / 100)

    # Alcohol recovered
    recovered_alcohol_gal = alcohol_volume_gal * collection_efficiency

    # Distillate volume at collection strength
    distillate_gal = recovered_alcohol_gal / (collection_abv / 100)

    # Also express at final bottle strength
    bottle_abv = 40.0
    bottle_volume_gal = recovered_alcohol_gal / (bottle_abv / 100)

    return {
        "total_alcohol_in_wash_gal": round(alcohol_volume_gal, 3),
        "recovered_alcohol_gal": round(recovered_alcohol_gal, 3),
        "distillate_volume_gal": round(distillate_gal, 3),
        "distillate_volume_ml": round(distillate_gal * ML_PER_GALLON, 0),
        "collection_abv": collection_abv,
        "at_40_abv_gal": round(bottle_volume_gal, 3),
        "at_40_abv_ml": round(bottle_volume_gal * ML_PER_GALLON, 0),
        "at_40_abv_750ml_bottles": round(bottle_volume_gal * ML_PER_GALLON / 750, 1),
    }


def sugar_to_alcohol_yield(sugar_kg: float,
                            collection_abv: float = 75.0) -> Dict[str, float]:
    """
    Calculate alcohol yield from a known amount of sugar.

    Theoretical: 51.1% of sugar mass converts to ethanol.
    Practical: ~90% of theoretical due to byproducts.
    Result: ~0.55 L pure ethanol per kg sugar.

    Args:
        sugar_kg: Sugar weight in kilograms
        collection_abv: Collection strength (e.g., 75%)

    Returns:
        Dict with ethanol and distillate volumes
    """
    # Pure ethanol yield: 0.55 L per kg sugar (practical)
    pure_ethanol_liters = sugar_kg * 0.55

    # At collection strength
    distillate_liters = pure_ethanol_liters / (collection_abv / 100)

    # At 40% bottle strength
    bottle_liters = pure_ethanol_liters / 0.40

    return {
        "sugar_kg": sugar_kg,
        "sugar_lbs": round(sugar_kg * 2.20462, 2),
        "pure_ethanol_liters": round(pure_ethanol_liters, 2),
        "distillate_liters_at_collection": round(distillate_liters, 2),
        "collection_abv": collection_abv,
        "at_40_abv_liters": round(bottle_liters, 2),
        "at_40_abv_750ml_bottles": round(bottle_liters * 1000 / 750, 1),
    }


# =============================================================================
# DILUTION AND PROOFING
# =============================================================================

def dilution_water(spirit_volume: float, spirit_abv: float,
                   target_abv: float) -> Dict[str, float]:
    """
    Calculate water needed to dilute a spirit to target ABV.
    Uses C1V1 = C2V2 → V2 = (C1 × V1) / C2, water = V2 - V1.

    Note: Does not account for volume contraction when mixing ethanol
    and water. Actual final volume will be slightly less. Approach
    target by adding water incrementally and re-measuring.

    Args:
        spirit_volume: Current volume of spirit (any unit)
        spirit_abv: Current ABV of spirit
        target_abv: Desired ABV

    Returns:
        Dict with water to add and final volume
    """
    if target_abv <= 0 or target_abv >= spirit_abv:
        return {"error": "Target ABV must be less than current ABV and greater than 0"}

    final_volume = (spirit_abv * spirit_volume) / target_abv
    water_to_add = final_volume - spirit_volume

    return {
        "water_to_add": round(water_to_add, 2),
        "final_volume": round(final_volume, 2),
        "spirit_volume": spirit_volume,
        "spirit_abv": spirit_abv,
        "target_abv": target_abv,
        "target_proof": abv_to_proof(target_abv),
        "note": "Volume contraction is not factored in. Add water gradually and re-measure.",
    }


def dilution_water_by_proof(spirit_volume: float, spirit_proof: float,
                             target_proof: float) -> Dict[str, float]:
    """
    Calculate water needed to dilute a spirit to target proof.

    Args:
        spirit_volume: Current volume
        spirit_proof: Current US proof
        target_proof: Desired US proof
    """
    return dilution_water(spirit_volume, spirit_proof / 2, target_proof / 2)


# =============================================================================
# BLENDING AND FORTIFICATION
# =============================================================================

def blend_spirits(volume_a: float, abv_a: float,
                  volume_b: float, abv_b: float) -> Dict[str, float]:
    """
    Calculate resulting ABV when blending two spirits.

    Args:
        volume_a: Volume of spirit A
        abv_a: ABV of spirit A
        volume_b: Volume of spirit B
        abv_b: ABV of spirit B

    Returns:
        Dict with blended volume and ABV
    """
    total_alcohol = (volume_a * abv_a / 100) + (volume_b * abv_b / 100)
    total_volume = volume_a + volume_b

    if total_volume <= 0:
        return {"error": "Total volume must be greater than 0"}

    blended_abv = (total_alcohol / total_volume) * 100

    return {
        "blended_volume": round(total_volume, 2),
        "blended_abv": round(blended_abv, 2),
        "blended_proof": abv_to_proof(blended_abv),
        "total_alcohol": round(total_alcohol, 3),
    }


def fortification_spirit_needed(wine_volume: float, wine_abv: float,
                                 target_abv: float,
                                 spirit_abv: float = 95.0) -> Dict[str, float]:
    """
    Calculate spirit volume needed to fortify a wine/wash to target ABV.
    Uses Pearson's Square: spirit_vol = wine_vol × (target - wine) / (spirit - target)

    Args:
        wine_volume: Volume of wine/wash to fortify
        wine_abv: Current ABV of wine/wash
        target_abv: Desired final ABV
        spirit_abv: ABV of fortifying spirit

    Returns:
        Dict with spirit volume needed and final volume
    """
    if not (wine_abv < target_abv < spirit_abv):
        return {"error": "Target ABV must be between wine ABV and spirit ABV"}

    spirit_needed = wine_volume * (target_abv - wine_abv) / (spirit_abv - target_abv)
    final_volume = wine_volume + spirit_needed

    # Pearson's Square parts
    parts_wine = spirit_abv - target_abv
    parts_spirit = target_abv - wine_abv
    total_parts = parts_wine + parts_spirit

    return {
        "spirit_volume_needed": round(spirit_needed, 2),
        "final_volume": round(final_volume, 2),
        "spirit_percentage": round((spirit_needed / final_volume) * 100, 1),
        "wine_percentage": round((wine_volume / final_volume) * 100, 1),
        "pearsons_parts_wine": round(parts_wine, 1),
        "pearsons_parts_spirit": round(parts_spirit, 1),
    }


def pearsons_square(concentration_a: float, concentration_b: float,
                    target: float) -> Dict[str, float]:
    """
    General Pearson's Square calculation for blending two solutions.
    Works for ABV, acidity, sugar content, or any blendable property.

    Args:
        concentration_a: Concentration of solution A (higher)
        concentration_b: Concentration of solution B (lower)
        target: Desired concentration in blend

    Returns:
        Parts of each solution needed
    """
    if not (min(concentration_a, concentration_b) <= target <=
            max(concentration_a, concentration_b)):
        return {"error": "Target must be between the two concentrations"}

    parts_a = abs(target - concentration_b)
    parts_b = abs(concentration_a - target)
    total_parts = parts_a + parts_b

    return {
        "parts_a": round(parts_a, 2),
        "parts_b": round(parts_b, 2),
        "total_parts": round(total_parts, 2),
        "ratio_a": round(parts_a / total_parts, 4),
        "ratio_b": round(parts_b / total_parts, 4),
        "pct_a": round((parts_a / total_parts) * 100, 1),
        "pct_b": round((parts_b / total_parts) * 100, 1),
    }


# =============================================================================
# TEMPERATURE CORRECTIONS
# =============================================================================

def hydrometer_temp_correction_abv(reading_abv: float,
                                    sample_temp_f: float,
                                    calibration_temp_f: float = 60.0) -> float:
    """
    Approximate temperature correction for alcohol hydrometer readings.

    Rule of thumb: For every 1°C above calibration temperature,
    subtract 0.33% ABV from the reading (and vice versa).

    This is an approximation. For TTB-accurate proofing, use the
    official TTB Table 1 or AlcoDens software.

    Args:
        reading_abv: Hydrometer ABV reading
        sample_temp_f: Sample temperature in °F
        calibration_temp_f: Hydrometer calibration temperature in °F (usually 60°F)

    Returns:
        Corrected ABV
    """
    temp_diff_c = (sample_temp_f - calibration_temp_f) * 5 / 9
    correction = temp_diff_c * 0.33

    corrected = reading_abv - correction
    return round(corrected, 1)


def hydrometer_temp_correction_sg(reading_sg: float,
                                   sample_temp_f: float,
                                   calibration_temp_f: float = 60.0) -> float:
    """
    Approximate temperature correction for specific gravity hydrometer.
    Uses polynomial approximation.

    Args:
        reading_sg: Hydrometer SG reading
        sample_temp_f: Sample temperature in °F
        calibration_temp_f: Hydrometer calibration temperature in °F

    Returns:
        Corrected SG
    """
    # Convert to Celsius for the polynomial
    temp_c = (sample_temp_f - 32) * 5 / 9
    cal_c = (calibration_temp_f - 32) * 5 / 9

    # Polynomial correction for wort/sugar solutions
    # Correction = SG × (1.00130346 - 1.34722124e-4 × T + 2.04052596e-6 × T² - 2.32820948e-9 × T³)
    # This is approximate; for spirits use TTB tables
    correction_sample = (1.00130346
                         - 1.34722124e-4 * temp_c
                         + 2.04052596e-6 * temp_c**2
                         - 2.32820948e-9 * temp_c**3)
    correction_cal = (1.00130346
                      - 1.34722124e-4 * cal_c
                      + 2.04052596e-6 * cal_c**2
                      - 2.32820948e-9 * cal_c**3)

    corrected = reading_sg * (correction_cal / correction_sample)
    return round(corrected, 4)


# =============================================================================
# EQUIPMENT AND ENERGY CALCULATIONS
# =============================================================================

def heating_time(volume_gallons: float, start_temp_f: float,
                 end_temp_f: float, power_watts: float,
                 efficiency: float = 0.80) -> Dict[str, float]:
    """
    Calculate time to heat liquid from start to end temperature.

    Args:
        volume_gallons: Liquid volume in gallons
        start_temp_f: Starting temperature in °F
        end_temp_f: Ending temperature in °F
        power_watts: Heat source power in watts
        efficiency: Heating efficiency (0.70-0.95 depending on insulation)

    Returns:
        Dict with heating time in minutes and hours
    """
    if power_watts <= 0 or efficiency <= 0:
        return {"error": "Power and efficiency must be greater than 0"}

    # Convert to metric for calculation
    mass_grams = volume_gallons * LBS_PER_GALLON * GRAMS_PER_LB
    start_c = (start_temp_f - 32) * 5 / 9
    end_c = (end_temp_f - 32) * 5 / 9
    delta_t = end_c - start_c

    if delta_t <= 0:
        return {"error": "End temperature must be greater than start temperature"}

    # Energy needed: Q = m × c × ΔT (in calories)
    energy_cal = mass_grams * SPECIFIC_HEAT_WATER * delta_t

    # Power available: watts × efficiency × cal_per_watt_second
    power_cal_per_sec = power_watts * WATTS_TO_CAL_PER_SEC * efficiency

    # Time in seconds, then minutes
    time_seconds = energy_cal / power_cal_per_sec
    time_minutes = time_seconds / 60

    return {
        "time_minutes": round(time_minutes, 1),
        "time_hours": round(time_minutes / 60, 2),
        "power_watts": power_watts,
        "efficiency_pct": round(efficiency * 100, 1),
        "volume_gallons": volume_gallons,
        "temp_rise_f": round(end_temp_f - start_temp_f, 1),
    }


def heating_time_btu(volume_gallons: float, start_temp_f: float,
                     end_temp_f: float, btu_per_hour: float,
                     efficiency: float = 0.80) -> Dict[str, float]:
    """
    Calculate heating time using BTU/hr heat source.
    Converts BTU/hr to watts internally.
    """
    watts = btu_per_hour * 0.293071
    result = heating_time(volume_gallons, start_temp_f, end_temp_f, watts, efficiency)
    result["btu_per_hour"] = btu_per_hour
    result["equivalent_watts"] = round(watts, 0)
    return result


def vapor_speed(column_diameter_inches: float,
                power_watts: float) -> Dict[str, float]:
    """
    Estimate vapor speed in a distillation column.

    Vapor speed is nearly independent of ABV (water vapor and ethanol vapor
    have similar volumes at a given power input). Higher speed reduces
    contact time with packing, reducing separation efficiency.

    Recommended max: ~50 cm/s (20 in/s) for packed columns.
    Recommended max: ~100 cm/s (40 in/s) for plate columns.

    Args:
        column_diameter_inches: Internal diameter of column in inches
        power_watts: Power input in watts

    Returns:
        Dict with vapor speed in cm/s and inches/s
    """
    # Cross-sectional area in cm²
    diameter_cm = column_diameter_inches * 2.54
    area_cm2 = math.pi * (diameter_cm / 2) ** 2

    # Approximate vapor volume flow rate
    # At ~100°C, 1 watt produces approximately 1.58 cm³/s of steam
    # (derived from: 1W = 1J/s, latent heat of vaporization of water ≈ 2260 J/g,
    #  density of steam at 100°C ≈ 0.598 kg/m³ → ~1672 cm³/g)
    # So 1W → (1/2260)g/s × 1672 cm³/g ≈ 0.74 cm³/s
    # Practical calibration from homedistiller data: ~0.84 cm³/s per watt
    vapor_flow_cm3_per_sec = power_watts * 0.84

    speed_cm_per_sec = vapor_flow_cm3_per_sec / area_cm2
    speed_in_per_sec = speed_cm_per_sec / 2.54

    # Assessment
    if speed_cm_per_sec > 150:
        assessment = "Too fast — likely flooding. Reduce power or increase column diameter."
    elif speed_cm_per_sec > 100:
        assessment = "High — acceptable for plates, too fast for packed columns."
    elif speed_cm_per_sec > 50:
        assessment = "Moderate — good for plates, borderline for packed columns."
    elif speed_cm_per_sec > 20:
        assessment = "Good range for packed reflux columns."
    else:
        assessment = "Slow — good separation but low throughput."

    return {
        "vapor_speed_cm_per_sec": round(speed_cm_per_sec, 1),
        "vapor_speed_in_per_sec": round(speed_in_per_sec, 1),
        "column_diameter_inches": column_diameter_inches,
        "power_watts": power_watts,
        "cross_section_cm2": round(area_cm2, 1),
        "assessment": assessment,
    }


# =============================================================================
# COLUMN DESIGN
# =============================================================================

def theoretical_plates(packing_height_cm: float,
                       hetp_cm: float = 2.0) -> float:
    """
    Calculate number of theoretical plates from packing height.
    NTP = Packing_Height / HETP

    Args:
        packing_height_cm: Height of packing in cm
        hetp_cm: Height Equivalent to a Theoretical Plate (cm)
                 Typical values: 1.5-3.0 cm for structured packing,
                 3-6 cm for random packing (Raschig rings, etc.)

    Returns:
        Number of theoretical plates
    """
    return round(packing_height_cm / hetp_cm, 1)


def packing_height_needed(target_plates: float,
                           hetp_cm: float = 2.0) -> float:
    """
    Calculate packing height needed for a target number of theoretical plates.

    Args:
        target_plates: Desired number of theoretical plates
        hetp_cm: HETP value in cm

    Returns:
        Required packing height in cm
    """
    return round(target_plates * hetp_cm, 1)


def hetp_from_packing_size(packing_diameter_mm: float) -> float:
    """
    Estimate HETP from random packing size.
    HETP (m) ≈ packing_diameter_mm / 60

    Args:
        packing_diameter_mm: Packing element diameter in mm

    Returns:
        Estimated HETP in cm
    """
    hetp_m = packing_diameter_mm / 60
    return round(hetp_m * 100, 1)  # Convert to cm


def reflux_ratio(vapor_rate: float, distillate_rate: float) -> float:
    """
    Calculate reflux ratio.
    R = L / D = (V - D) / D

    Args:
        vapor_rate: Total vapor rate (volume/time)
        distillate_rate: Distillate collection rate (volume/time)

    Returns:
        Reflux ratio
    """
    if distillate_rate <= 0:
        return float('inf')
    liquid_return = vapor_rate - distillate_rate
    return round(liquid_return / distillate_rate, 2)


def recommended_column_power(column_diameter_inches: float) -> Dict[str, float]:
    """
    Recommended power range for a given column diameter.
    Based on practical guidelines from homedistiller.org.

    Args:
        column_diameter_inches: Column inner diameter in inches

    Returns:
        Dict with min and max recommended watts
    """
    # Approximate power ranges based on column area
    # 2" column: 750-2500W
    # 3" column: 1500-4500W
    # 4" column: 2400-8000W
    area_ratio = (column_diameter_inches / 2.0) ** 2

    min_watts = round(750 * area_ratio)
    max_watts = round(2500 * area_ratio)

    return {
        "column_diameter_inches": column_diameter_inches,
        "min_watts": min_watts,
        "max_watts": max_watts,
        "recommended_watts": round((min_watts + max_watts) / 2),
    }


# =============================================================================
# CUTS ESTIMATION
# =============================================================================

# Approximate boiling points of key congeners and compounds
BOILING_POINTS = {
    "acetone":          {"bp_c": 56.2, "bp_f": 133.2, "category": "foreshots"},
    "methanol":         {"bp_c": 64.7, "bp_f": 148.5, "category": "foreshots"},
    "ethyl_acetate":    {"bp_c": 77.1, "bp_f": 170.8, "category": "heads"},
    "ethanol":          {"bp_c": 78.4, "bp_f": 173.1, "category": "hearts"},
    "2_propanol":       {"bp_c": 82.6, "bp_f": 180.7, "category": "heads"},
    "1_propanol":       {"bp_c": 97.0, "bp_f": 206.6, "category": "tails"},
    "water":            {"bp_c": 100.0, "bp_f": 212.0, "category": "tails"},
    "butanol":          {"bp_c": 117.7, "bp_f": 243.9, "category": "tails"},
    "amyl_alcohol":     {"bp_c": 138.0, "bp_f": 280.4, "category": "tails"},
    "furfural":         {"bp_c": 161.7, "bp_f": 323.1, "category": "tails"},
    "acetic_acid":      {"bp_c": 118.1, "bp_f": 244.6, "category": "tails"},
}


def estimate_cuts(wash_volume_gallons: float,
                  wash_abv: float) -> Dict[str, Union[str, float]]:
    """
    Estimate approximate cut volumes for a stripping run.

    These are rough guidelines only. Actual cuts should be made
    by taste, smell, and temperature observation.

    Rule of thumb:
    - Foreshots: ~100-150 mL per 5 gallons of wash (discard always)
    - Heads: ~10-20% of total expected distillate
    - Hearts: ~30-50% of total expected distillate
    - Tails: remainder

    Args:
        wash_volume_gallons: Wash volume in gallons
        wash_abv: Wash ABV percentage

    Returns:
        Dict with estimated cut volumes in mL
    """
    # Total alcohol in wash (mL)
    total_alcohol_ml = wash_volume_gallons * ML_PER_GALLON * (wash_abv / 100)

    # Rough total distillate (at ~50% average collection)
    total_distillate_ml = total_alcohol_ml / 0.50

    # Foreshots: ~30 mL per gallon of wash
    foreshots_ml = wash_volume_gallons * 30

    # Remaining after foreshots
    remaining = total_distillate_ml - foreshots_ml

    # Heads: ~15% of remaining
    heads_ml = remaining * 0.15

    # Hearts: ~40% of remaining
    hearts_ml = remaining * 0.40

    # Tails: ~45% of remaining
    tails_ml = remaining * 0.45

    return {
        "total_distillate_ml": round(total_distillate_ml, 0),
        "foreshots_ml": round(foreshots_ml, 0),
        "heads_ml": round(heads_ml, 0),
        "hearts_ml": round(hearts_ml, 0),
        "tails_ml": round(tails_ml, 0),
        "note": "These are rough estimates. Make actual cuts by taste, smell, and temperature.",
        "foreshots_note": "Always discard foreshots. Contains methanol and acetone.",
        "heads_note": "Solvent/nail polish aromas. Save for feints or re-distillation.",
        "hearts_note": "Sweet, clean spirit character. This is your product.",
        "tails_note": "Wet cardboard, oily. Can add back to next stripping run.",
    }


# =============================================================================
# BOTTLE YIELD
# =============================================================================

def bottle_yield(total_volume_ml: float,
                 bottle_size_ml: float = 750) -> Dict[str, float]:
    """
    Calculate number of bottles from total distillate volume.

    Args:
        total_volume_ml: Total volume in mL
        bottle_size_ml: Bottle size in mL (default 750mL)

    Returns:
        Dict with bottle count
    """
    bottles = total_volume_ml / bottle_size_ml
    return {
        "full_bottles": math.floor(bottles),
        "total_bottles_exact": round(bottles, 2),
        "remainder_ml": round(total_volume_ml % bottle_size_ml, 0),
        "bottle_size_ml": bottle_size_ml,
        "total_volume_ml": total_volume_ml,
    }


# =============================================================================
# UNIT CONVERSIONS
# =============================================================================

def fahrenheit_to_celsius(f: float) -> float:
    return round((f - 32) * 5 / 9, 1)


def celsius_to_fahrenheit(c: float) -> float:
    return round((c * 9 / 5) + 32, 1)


def gallons_to_liters(gal: float) -> float:
    return round(gal * LITERS_PER_GALLON, 2)


def liters_to_gallons(l: float) -> float:
    return round(l / LITERS_PER_GALLON, 2)


def btu_to_watts(btu_hr: float) -> float:
    return round(btu_hr * 0.293071, 1)


def watts_to_btu(watts: float) -> float:
    return round(watts / 0.293071, 1)


def glucose_equivalent_sugar(sugar_weight: float) -> float:
    """Glucose requires 12.5% more weight than sucrose for same result."""
    return round(sugar_weight * 1.125, 2)


# =============================================================================
# MAIN / EXAMPLES
# =============================================================================

if __name__ == "__main__":
    print("=== Distilling Calculator Examples ===\n")

    # --- Sugar Wash ---
    print("--- Sugar Wash (5 gal, 10% ABV target) ---")
    sw = sugar_for_target_abv(5, 10)
    print(f"  Sugar needed: {sw['sugar_lbs']} lbs ({sw['sugar_kg']} kg)")
    print(f"  Estimated OG: {sw['estimated_og']}")

    print()

    # --- Wash ABV from gravity ---
    print("--- Wash ABV from Gravity ---")
    og, fg = 1.080, 1.000
    abv = abv_from_gravity(og, fg)
    print(f"  OG {og} → FG {fg} = {abv}% ABV ({abv_to_proof(abv)} proof)")

    print()

    # --- Distillate yield ---
    print("--- Distillate Yield (5 gal wash @ 10% ABV) ---")
    dy = distillate_yield_from_wash(5, 10, collection_abv=65)
    print(f"  Total alcohol in wash: {dy['total_alcohol_in_wash_gal']} gal")
    print(f"  Distillate at 65% ABV: {dy['distillate_volume_ml']} mL")
    print(f"  At 40% ABV (bottle): {dy['at_40_abv_ml']} mL ({dy['at_40_abv_750ml_bottles']} bottles)")

    print()

    # --- Dilution ---
    print("--- Dilution (750 mL spirit @ 65% ABV → 40% ABV) ---")
    dil = dilution_water(750, 65, 40)
    print(f"  Water to add: {dil['water_to_add']} mL")
    print(f"  Final volume: {dil['final_volume']} mL")

    print()

    # --- Blending ---
    print("--- Blending Two Spirits ---")
    b = blend_spirits(500, 60, 300, 45)
    print(f"  500mL @ 60% + 300mL @ 45% = {b['blended_volume']}mL @ {b['blended_abv']}% ABV")

    print()

    # --- Fortification (Pearson's Square) ---
    print("--- Fortification (1 gal wine @ 12% → 18% using 40% brandy) ---")
    f = fortification_spirit_needed(128, 12, 18, 40)  # 128 oz = 1 gallon
    print(f"  Spirit needed: {f['spirit_volume_needed']} oz")
    print(f"  Final volume: {f['final_volume']} oz")
    print(f"  Blend: {f['wine_percentage']}% wine, {f['spirit_percentage']}% spirit")

    print()

    # --- Heating time ---
    print("--- Heating Time (5 gal, 65°F → 173°F, 2000W, 80% eff) ---")
    ht = heating_time(5, 65, 173, 2000, 0.80)
    print(f"  Time: {ht['time_minutes']} min ({ht['time_hours']} hr)")

    print()

    # --- Vapor speed ---
    print("--- Vapor Speed (2\" column, 1500W) ---")
    vs = vapor_speed(2, 1500)
    print(f"  Speed: {vs['vapor_speed_cm_per_sec']} cm/s ({vs['vapor_speed_in_per_sec']} in/s)")
    print(f"  Assessment: {vs['assessment']}")

    print()

    # --- Column design ---
    print("--- Column Packing (30cm packing, 2cm HETP) ---")
    plates = theoretical_plates(30, 2.0)
    print(f"  Theoretical plates: {plates}")
    print(f"  Recommended power for 2\" column: {recommended_column_power(2)}")

    print()

    # --- Cuts estimate ---
    print("--- Estimated Cuts (5 gal wash @ 10% ABV) ---")
    cuts = estimate_cuts(5, 10)
    print(f"  Total distillate: ~{cuts['total_distillate_ml']} mL")
    print(f"  Foreshots (discard): ~{cuts['foreshots_ml']} mL")
    print(f"  Heads: ~{cuts['heads_ml']} mL")
    print(f"  Hearts: ~{cuts['hearts_ml']} mL")
    print(f"  Tails: ~{cuts['tails_ml']} mL")

    print()

    # --- Sugar yield ---
    print("--- Sugar to Alcohol (5 kg sugar) ---")
    sy = sugar_to_alcohol_yield(5, collection_abv=75)
    print(f"  Pure ethanol: {sy['pure_ethanol_liters']} L")
    print(f"  At 75% collection: {sy['distillate_liters_at_collection']} L")
    print(f"  At 40% bottle: {sy['at_40_abv_liters']} L ({sy['at_40_abv_750ml_bottles']} bottles)")
