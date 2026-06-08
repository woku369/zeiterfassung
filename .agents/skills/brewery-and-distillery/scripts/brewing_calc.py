#!/usr/bin/env python3
"""
Brewing Calculator Library
Formulas derived from Brewer's Friend calculators and standard brewing science.
"""

import math
from typing import Dict, List, Optional, Tuple, Union

# Mathematical constant
E = 2.718281828459045


# =============================================================================
# GRAVITY CALCULATIONS
# =============================================================================

def gravity_to_plato(gravity: float) -> float:
    """Convert specific gravity to degrees Plato."""
    return (-616.868) + (1111.14 * gravity) - (630.272 * gravity**2) + (135.997 * gravity**3)


def plato_to_gravity(plato: float) -> float:
    """Convert degrees Plato to specific gravity."""
    return (plato / (258.6 - ((plato / 258.2) * 227.1))) + 1


def brix_to_gravity(brix: float) -> float:
    """Convert Brix to specific gravity (pre-fermentation)."""
    return plato_to_gravity(brix)


def gravity_points(gravity: float) -> float:
    """Extract gravity points from specific gravity (e.g., 1.050 -> 50)."""
    return (gravity - 1) * 1000


def points_to_gravity(points: float) -> float:
    """Convert gravity points to specific gravity (e.g., 50 -> 1.050)."""
    return (points / 1000) + 1


def calculate_og(total_points: float, volume_gallons: float) -> float:
    """
    Calculate original gravity from total grain points and volume.

    Args:
        total_points: Sum of (grain_lbs * PPG * efficiency) for all grains
        volume_gallons: Final batch volume in gallons
    """
    return ((total_points / volume_gallons) * 0.001) + 1


def calculate_boil_gravity(batch_volume: float, boil_volume: float, og: float) -> float:
    """
    Calculate pre-boil gravity from batch parameters.

    Args:
        batch_volume: Final batch volume
        boil_volume: Pre-boil volume
        og: Target original gravity
    """
    if batch_volume <= 0 or boil_volume <= 0 or og <= 0:
        return 0
    return ((batch_volume / boil_volume) * (og - 1)) + 1


def estimate_fg(og: float, attenuation: float = 0.75) -> float:
    """
    Estimate final gravity based on yeast attenuation.

    Args:
        og: Original gravity
        attenuation: Apparent attenuation as decimal (e.g., 0.75 for 75%)
    """
    og_points = gravity_points(og)
    fg_points = og_points * (1 - attenuation)
    return points_to_gravity(fg_points)


# =============================================================================
# ABV CALCULATIONS
# =============================================================================

def calculate_abv_standard(og: float, fg: float) -> float:
    """
    Calculate ABV using standard formula.
    ABV = (OG - FG) × 131.25

    Accurate for most normal-strength beers.
    """
    return round((og - fg) * 131.25, 2)


def calculate_abv_alternate(og: float, fg: float) -> float:
    """
    Calculate ABV using alternate formula (more accurate for high-gravity beers).
    Based on Cutaia, Reid, and Speers formula.

    ABV = (76.08 × (OG - FG) / (1.775 - OG)) × (FG / 0.794)
    """
    abv = 76.08 * (og - fg) / (1.775 - og)
    abv = abv * (fg / 0.794)
    return round(abv, 2)


def abv_from_refractometer(og_brix: float, fg_brix: float, wcf: float = 1.04) -> float:
    """
    Calculate ABV from refractometer readings (corrected for alcohol).

    Args:
        og_brix: Original gravity in Brix
        fg_brix: Final gravity in Brix (uncorrected reading)
        wcf: Wort correction factor (typically 1.02-1.06, default 1.04)
    """
    og_brix_corrected = og_brix / wcf
    # Sean Terrill's formula for FG from refractometer
    fg = 1 + 0.006276 * fg_brix - 0.002349 * og_brix_corrected
    og = brix_to_gravity(og_brix_corrected)
    return calculate_abv_standard(og, fg)


# =============================================================================
# IBU CALCULATIONS
# =============================================================================

def ibu_tinseth(og: float, boil_minutes: float, alpha_acid: float,
                hop_oz: float, volume_gallons: float) -> float:
    """
    Calculate IBU using Tinseth formula.

    Args:
        og: Boil gravity (use pre-boil gravity for accuracy)
        boil_minutes: Hop boil time in minutes
        alpha_acid: Alpha acid percentage (e.g., 6.5 for 6.5%)
        hop_oz: Hop weight in ounces
        volume_gallons: Final batch volume in gallons
    """
    # Bigness factor (accounts for gravity's effect on utilization)
    bigness = 1.65 * math.pow(0.000125, (og - 1))

    # Boil time factor
    boil_factor = (1 - math.pow(E, (-0.04 * boil_minutes))) / 4.15

    # Utilization
    utilization = bigness * boil_factor

    # IBU calculation
    # 7490 is the constant for converting to metric IBUs
    ibu = utilization * ((alpha_acid / 100) * hop_oz * 7490) / volume_gallons

    return round(ibu, 1)


def ibu_rager(og: float, boil_minutes: float, alpha_acid: float,
              hop_oz: float, volume_gallons: float) -> float:
    """
    Calculate IBU using Rager formula.

    Args:
        og: Boil gravity
        boil_minutes: Hop boil time in minutes
        alpha_acid: Alpha acid percentage (e.g., 6.5 for 6.5%)
        hop_oz: Hop weight in ounces
        volume_gallons: Final batch volume in gallons
    """
    # Rager utilization (hyperbolic tangent based)
    if boil_minutes <= 5:
        utilization = 0.01 * boil_minutes
    else:
        # tanh approximation: sinh(x)/cosh(x)
        x = (boil_minutes - 31.32) / 18.27
        sinh_x = (math.pow(E, x) - math.pow(E, -x)) / 2
        cosh_x = (math.pow(E, x) + math.pow(E, -x)) / 2
        tanh_x = sinh_x / cosh_x
        utilization = (18.11 + (13.86 * tanh_x)) / 100

    # Gravity adjustment (Rager applies for OG > 1.050)
    if og > 1.050:
        gravity_adjustment = (og - 1.050) / 0.2
    else:
        gravity_adjustment = 0

    # IBU calculation
    ibu = (hop_oz * utilization * alpha_acid * 7489) / (volume_gallons * (1 + gravity_adjustment))

    return round(ibu, 1)


def utilization_from_altitude(altitude_feet: float) -> float:
    """
    Calculate hop utilization adjustment factor for altitude.
    Higher altitudes have lower boiling points, reducing utilization.
    """
    return round(1 / (((altitude_feet / 550) * 0.02) + 1), 2)


# =============================================================================
# COLOR CALCULATIONS
# =============================================================================

def calculate_mcu(lovibond: float, grain_lbs: float, volume_gallons: float) -> float:
    """
    Calculate Malt Color Units for a single grain addition.
    MCU = (Lovibond × Weight_lbs) / Volume_gallons
    """
    if volume_gallons <= 0:
        return 0
    return (lovibond * grain_lbs) / volume_gallons


def srm_morey(mcu: float) -> float:
    """
    Calculate SRM using Morey formula (most accurate for typical beers).
    SRM = 1.4922 × MCU^0.6859
    """
    if mcu <= 0:
        return 0
    return round(1.4922 * math.pow(mcu, 0.6859), 1)


def srm_daniels(mcu: float) -> float:
    """
    Calculate SRM using Daniels formula.
    SRM = 0.2 × MCU + 8.4 (for MCU > 8)
    SRM = 0.3 × MCU + 4.7 (for MCU ≤ 8)
    """
    if mcu <= 0:
        return 0
    if mcu > 8:
        return round(0.2 * mcu + 8.4, 1)
    return round(0.3 * mcu + 4.7, 1)


def srm_mosher(mcu: float) -> float:
    """
    Calculate SRM using Mosher formula.
    SRM = 0.3 × MCU + 4.7
    """
    if mcu <= 0:
        return 0
    return round(0.3 * mcu + 4.7, 1)


def srm_to_ebc(srm: float) -> float:
    """Convert SRM to EBC (European Brewing Convention) color units."""
    return round(srm * 1.97, 1)


def ebc_to_srm(ebc: float) -> float:
    """Convert EBC to SRM color units."""
    return round(ebc * 0.508, 1)


def srm_to_lovibond(srm: float) -> float:
    """Convert SRM to Lovibond."""
    return round((srm + 0.76) / 1.3546, 1)


def lovibond_to_srm(lovibond: float) -> float:
    """Convert Lovibond to SRM."""
    return round((1.3546 * lovibond) - 0.76, 1)


# =============================================================================
# EFFICIENCY & EXTRACT CALCULATIONS
# =============================================================================

def ppg_from_extract(extract_percent: float) -> float:
    """
    Calculate Points Per Pound Per Gallon from extract percentage.
    PPG = Extract% × 0.46
    """
    return round(extract_percent / 100 * 46, 1)


def extract_from_ppg(ppg: float) -> float:
    """
    Calculate extract percentage from PPG.
    Extract% = PPG / 0.46
    """
    return round(ppg / 46 * 100, 1)


def calculate_efficiency(og: float, grain_lbs: float,
                         volume_gallons: float, total_ppg: float) -> float:
    """
    Calculate mash efficiency from actual OG achieved.

    Args:
        og: Measured original gravity
        grain_lbs: Total grain weight in pounds
        volume_gallons: Batch volume in gallons
        total_ppg: Weighted average PPG of grain bill
    """
    actual_points = gravity_points(og) * volume_gallons
    potential_points = grain_lbs * total_ppg
    if potential_points <= 0:
        return 0
    return round((actual_points / potential_points) * 100, 1)


def scale_recipe_by_efficiency(current_grain_lbs: float,
                                current_efficiency: float,
                                target_efficiency: float) -> float:
    """
    Scale grain bill for different mash efficiency.

    Args:
        current_grain_lbs: Current grain weight
        current_efficiency: Efficiency the recipe was designed for
        target_efficiency: Your actual mash efficiency
    """
    return round(current_grain_lbs * (current_efficiency / target_efficiency), 2)


def scale_recipe_by_volume(current_amount: float,
                           current_volume: float,
                           target_volume: float) -> float:
    """
    Scale any ingredient amount for different batch volume.
    """
    return round(current_amount * (target_volume / current_volume), 2)


# =============================================================================
# MASH CALCULATIONS
# =============================================================================

def strike_water_temp(target_mash_temp: float, grain_temp: float,
                      ratio_qt_per_lb: float) -> float:
    """
    Calculate strike water temperature.

    Args:
        target_mash_temp: Desired mash temperature (°F)
        grain_temp: Temperature of grain (°F)
        ratio_qt_per_lb: Water-to-grain ratio in quarts per pound

    Returns:
        Strike water temperature in °F
    """
    # Standard formula: Tw = (0.2/R)(T2-T1) + T2
    # Where R = qt/lb ratio, T1 = grain temp, T2 = target mash temp
    strike_temp = (0.2 / ratio_qt_per_lb) * (target_mash_temp - grain_temp) + target_mash_temp
    return round(strike_temp, 1)


def infusion_water_volume(current_mash_temp: float, target_mash_temp: float,
                          grain_lbs: float, current_mash_volume_qt: float,
                          infusion_water_temp: float = 212) -> float:
    """
    Calculate infusion water volume needed to raise mash temperature.

    Args:
        current_mash_temp: Current mash temperature (°F)
        target_mash_temp: Target mash temperature (°F)
        grain_lbs: Total grain weight in pounds
        current_mash_volume_qt: Current mash water volume in quarts
        infusion_water_temp: Temperature of infusion water (°F), default boiling

    Returns:
        Volume of infusion water needed in quarts
    """
    # Wa = (T2 - T1)(0.2G + Wm) / (Tw - T2)
    # Where G = grain weight, Wm = mash water volume, Tw = infusion water temp
    volume = ((target_mash_temp - current_mash_temp) *
              (0.2 * grain_lbs + current_mash_volume_qt)) / \
             (infusion_water_temp - target_mash_temp)
    return round(volume, 2)


def mash_thickness_qt_lb_to_l_kg(qt_per_lb: float) -> float:
    """Convert mash thickness from qt/lb to L/kg."""
    return round(qt_per_lb * 2.0864, 2)


def mash_thickness_l_kg_to_qt_lb(l_per_kg: float) -> float:
    """Convert mash thickness from L/kg to qt/lb."""
    return round(l_per_kg / 2.0864, 2)


# =============================================================================
# PRIMING/CARBONATION CALCULATIONS
# =============================================================================

def priming_sugar_oz(volume_gallons: float, target_co2_volumes: float,
                     beer_temp_f: float, sugar_type: str = "corn") -> float:
    """
    Calculate priming sugar amount.

    Args:
        volume_gallons: Batch volume
        target_co2_volumes: Desired CO2 volumes (e.g., 2.4 for American ales)
        beer_temp_f: Beer temperature at packaging
        sugar_type: "corn" (dextrose), "table" (sucrose), or "dme" (dry malt extract)

    Returns:
        Sugar amount in ounces
    """
    # Residual CO2 based on temperature (approximation)
    residual_co2 = 3.0378 - (0.050062 * beer_temp_f) + (0.00026555 * beer_temp_f**2)

    co2_needed = target_co2_volumes - residual_co2

    # Sugar factors (grams CO2 per gram sugar)
    sugar_factors = {
        "corn": 0.91,      # Dextrose/corn sugar
        "table": 0.88,     # Sucrose/table sugar
        "dme": 0.71        # Dry malt extract
    }

    factor = sugar_factors.get(sugar_type, 0.91)

    # Grams of sugar needed
    grams = (co2_needed * volume_gallons * 3.785 * 4) / factor

    # Convert to ounces
    return round(grams / 28.35, 2)


# =============================================================================
# UNIT CONVERSIONS
# =============================================================================

def fahrenheit_to_celsius(f: float) -> float:
    """Convert Fahrenheit to Celsius."""
    return round((f - 32) * 5 / 9, 1)


def celsius_to_fahrenheit(c: float) -> float:
    """Convert Celsius to Fahrenheit."""
    return round((c * 9 / 5) + 32, 1)


def gallons_to_liters(gal: float) -> float:
    """Convert US gallons to liters."""
    return round(gal * 3.78541, 2)


def liters_to_gallons(l: float) -> float:
    """Convert liters to US gallons."""
    return round(l / 3.78541, 2)


def oz_to_grams(oz: float) -> float:
    """Convert ounces to grams."""
    return round(oz * 28.3495, 1)


def grams_to_oz(g: float) -> float:
    """Convert grams to ounces."""
    return round(g / 28.3495, 2)


def lbs_to_kg(lbs: float) -> float:
    """Convert pounds to kilograms."""
    return round(lbs * 0.453592, 2)


def kg_to_lbs(kg: float) -> float:
    """Convert kilograms to pounds."""
    return round(kg / 0.453592, 2)


# =============================================================================
# DIASTATIC POWER CONVERSIONS
# =============================================================================

def lintner_to_wk(lintner: float) -> float:
    """Convert Lintner to Windisch-Kolbach (WK) diastatic power."""
    return round(3.5 * lintner - 16, 1)


def wk_to_lintner(wk: float) -> float:
    """Convert Windisch-Kolbach (WK) to Lintner diastatic power."""
    return round((wk + 16) / 3.5, 1)


# =============================================================================
# YEAST CALCULATIONS
# =============================================================================

def yeast_cells_needed(og: float, volume_gallons: float,
                       pitch_rate: float = 0.75) -> float:
    """
    Calculate yeast cells needed for fermentation.

    Args:
        og: Original gravity
        volume_gallons: Batch volume in gallons
        pitch_rate: Millions of cells per mL per degree Plato
                   (0.75 for ales, 1.5 for lagers, 1.0 for high-gravity ales)

    Returns:
        Billions of cells needed
    """
    plato = gravity_to_plato(og)
    volume_ml = volume_gallons * 3785.41
    cells_millions = pitch_rate * plato * volume_ml
    return round(cells_millions / 1000, 0)  # Convert to billions


def yeast_starter_volume(cells_needed_billions: float,
                         starter_og: float = 1.036) -> float:
    """
    Calculate starter volume needed to grow yeast.

    Assumes standard 100 billion cells per liter growth rate
    with intermittent shaking, starting with ~100B cells.

    Args:
        cells_needed_billions: Target cell count in billions
        starter_og: Starter wort gravity (1.030-1.040 recommended)

    Returns:
        Starter volume in liters
    """
    # Simplified calculation - more accurate with online calculators
    # Assume ~100B cells starting, ~100B growth per liter
    cells_to_grow = cells_needed_billions - 100
    if cells_to_grow <= 0:
        return 0
    return round(cells_to_grow / 100, 1)


# =============================================================================
# RECIPE ANALYSIS
# =============================================================================

def analyze_recipe(grain_bill: List[Dict], hops: List[Dict],
                   batch_volume_gal: float, efficiency: float = 0.72,
                   boil_time: int = 60) -> Dict:
    """
    Analyze a complete recipe and return estimated statistics.

    Args:
        grain_bill: List of dicts with 'name', 'lbs', 'lovibond', 'ppg'
        hops: List of dicts with 'name', 'oz', 'aa', 'time'
        batch_volume_gal: Final batch volume in gallons
        efficiency: Mash efficiency as decimal
        boil_time: Total boil time in minutes

    Returns:
        Dict with og, fg, abv, ibu, srm, and other stats
    """
    # Calculate OG
    total_points = 0
    total_mcu = 0
    total_grain_lbs = 0

    for grain in grain_bill:
        points = grain['lbs'] * grain['ppg'] * efficiency
        total_points += points
        total_mcu += calculate_mcu(grain['lovibond'], grain['lbs'], batch_volume_gal)
        total_grain_lbs += grain['lbs']

    og = calculate_og(total_points, batch_volume_gal)

    # Estimate FG (assuming 75% attenuation)
    fg = estimate_fg(og, 0.75)

    # Calculate ABV
    abv = calculate_abv_standard(og, fg)

    # Calculate IBU (using Tinseth)
    total_ibu = 0
    boil_gravity = calculate_boil_gravity(batch_volume_gal, batch_volume_gal * 1.1, og)

    for hop in hops:
        ibu = ibu_tinseth(boil_gravity, hop['time'], hop['aa'],
                         hop['oz'], batch_volume_gal)
        total_ibu += ibu

    # Calculate SRM
    srm = srm_morey(total_mcu)

    # Calculate BU:GU ratio
    og_points = gravity_points(og)
    bu_gu = round(total_ibu / og_points, 2) if og_points > 0 else 0

    return {
        'og': round(og, 3),
        'fg': round(fg, 3),
        'abv': abv,
        'ibu': round(total_ibu, 1),
        'srm': srm,
        'ebc': srm_to_ebc(srm),
        'bu_gu_ratio': bu_gu,
        'total_grain_lbs': round(total_grain_lbs, 2),
        'mcu': round(total_mcu, 1)
    }


if __name__ == "__main__":
    # Example usage
    print("=== Brewing Calculator Examples ===\n")

    # ABV calculation
    og, fg = 1.052, 1.012
    print(f"OG: {og}, FG: {fg}")
    print(f"ABV (standard): {calculate_abv_standard(og, fg)}%")
    print(f"ABV (alternate): {calculate_abv_alternate(og, fg)}%")

    print()

    # IBU calculation
    ibu = ibu_tinseth(og=1.048, boil_minutes=60, alpha_acid=6.5,
                      hop_oz=1.5, volume_gallons=5)
    print(f"IBU (Tinseth): {ibu} (1.5oz @ 6.5% AA, 60min, 5gal, 1.048 OG)")

    print()

    # Color calculation
    mcu = calculate_mcu(lovibond=3.5, grain_lbs=10, volume_gallons=5)
    print(f"MCU: {mcu}")
    print(f"SRM (Morey): {srm_morey(mcu)}")

    print()

    # Strike water
    strike = strike_water_temp(target_mash_temp=152, grain_temp=68, ratio_qt_per_lb=1.25)
    print(f"Strike water temp: {strike}°F (for 152°F mash, 68°F grain, 1.25 qt/lb)")

    print()

    # Full recipe analysis
    recipe_grains = [
        {'name': 'Pale Malt', 'lbs': 10, 'lovibond': 2, 'ppg': 37},
        {'name': 'Crystal 60', 'lbs': 1, 'lovibond': 60, 'ppg': 34},
    ]
    recipe_hops = [
        {'name': 'Centennial', 'oz': 1.0, 'aa': 10.5, 'time': 60},
        {'name': 'Cascade', 'oz': 1.0, 'aa': 5.5, 'time': 15},
        {'name': 'Cascade', 'oz': 1.5, 'aa': 5.5, 'time': 0},
    ]

    stats = analyze_recipe(recipe_grains, recipe_hops, 5.5, efficiency=0.72)
    print("Recipe Analysis:")
    for key, value in stats.items():
        print(f"  {key}: {value}")
