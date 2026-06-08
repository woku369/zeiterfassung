EXTRACTED BREWING SCIENCE DATA
Source: Hough, Briggs, Stevens, and Young - "Malting and Brewing Science Vol. II:
        Hopped Wort and Beer" (2nd Edition, 1982)
Extraction date: 2026-01-27
================================================================================

This extraction focuses on actionable science data NOT already well-covered in the
existing brewery skill modules (which have comprehensive hop science, water chemistry,
core fermentation guidance, and yeast strain listings).

================================================================================
1. YEAST BIOLOGY AND FERMENTATION BIOCHEMISTRY
================================================================================

1.1 EMBDEN-MEYERHOF-PARNAS (EMP) PATHWAY - KEY NUMBERS
-------------------------------------------------------------
- Net ATP yield per glucose molecule (anaerobic): 2 ATP
- Standard free energy of hydrolysis of ATP to ADP: -30.5 kJ (-7.3 kcal) standard;
  up to -52 kJ (-12.5 kcal) under intracellular conditions
- Complete oxidation of glucose (aerobic): delta-G = -2.9 MJ (-688 kcal)
- Phosphoenolpyruvic acid bond energy: -61.9 kJ (-14.8 kcal)
- 1,3-diphosphoglyceric acid bond energy: -49.3 kJ (-11.8 kcal)
- NAD+ is the primary electron carrier; its supply is limited and must be
  regenerated for glycolysis to continue

Under AEROBIC conditions (low glucose): Pyruvate enters TCA cycle via pyruvate
dehydrogenase complex (mitochondrial), producing acetyl-CoA + CO2 + NADH.
  - Delta-G for this reaction: -33.4 kJ (-8 kcal) -- essentially irreversible
  - Requires: TPP, CoA, FAD, NAD+, dihydrolipoic acid

Under FERMENTATIVE conditions: Pyruvate -> Acetaldehyde + CO2 (by pyruvate
decarboxylase), then Acetaldehyde -> Ethanol (by alcohol dehydrogenase,
regenerating NAD+)

CRABTREE EFFECT: Even in the presence of oxygen, yeast ferments if glucose
concentration exceeds ~0.4% (the threshold for glucose repression of
respiratory enzymes). This is the normal situation in brewery fermentations.

1.2 GLYCEROL PRODUCTION
-------------------------------------------------------------
- Glycerol is quantitatively the most important non-ethanol metabolic product
- German beers: 1.5-1.95 g/L
- Canadian beers: 2.7-3.4 g/L
- Glycerol is produced by reduction of dihydroxyacetone phosphate (DHAP, a
  glycolytic intermediate) to alpha-glycerophosphate, then dephosphorylation
- This reaction also regenerates NAD+, serving as a redox safety valve when
  the normal ethanol pathway is insufficient
- Also formed: butane-2,3-diol (10-128 ppm) and acetoin (3-26 ppm), both
  reduction products of vicinal diketones

1.3 ESTER BIOSYNTHESIS - THE KEY MECHANISM
-------------------------------------------------------------
Esters are NOT formed by simple chemical condensation of alcohol + acid.
The uncatalyzed chemical rate is 1000x too slow to account for ester
formation during fermentation.

ACTUAL MECHANISM: Alcoholysis of acyl-CoA compounds
  Alcohol + Acyl-CoA -> Ester + CoASH

Sources of acyl-CoA for ester synthesis:
  1. Activation of wort fatty acids (RCOOH + CoASH -> RCOSCoA + H2O)
  2. Oxidative decarboxylation of oxo-acids
  3. Catabolism of fats (beta-oxidation)
  4. Fatty acid biosynthesis

KEY INSIGHT - Acetyl-CoA is the central metabolite controlling ester production:
  - Ethanol (most abundant alcohol) + Acetyl-CoA (most abundant acyl-CoA)
    = Ethyl acetate (most abundant ester)
  - ANY FACTOR that increases intracellular acetyl-CoA pool elevates ester production
  - ANY RESTRICTION OF CELL GROWTH leads to elevated acetate esters (because
    acetyl-CoA is not being consumed for biosynthesis)

OXYGEN/GROWTH LINK TO ESTERS:
  - When oxygen is limited, yeast cannot synthesize unsaturated fatty acids or sterols
  - Growth ceases, but acetyl-CoA still accumulates
  - If adequate amino nitrogen is present, elevated ester levels result
  - Adding oleic acid + ergosterol to "oxygen-starved" yeast restores normal
    (lower) ester levels by enabling growth to resume

PRACTICAL IMPLICATIONS:
  - Reducing dissolved O2 from 8 to 3 mg/L causes 2-4x increases in:
    ethyl acetate, isoamyl acetate, and ethyl caproate
  - Acetaldehyde rises 7-fold at low O2
  - High-gravity worts naturally restrict growth (insufficient O2 for the larger
    yeast population needed), leading to elevated esters

1.4 FUSEL ALCOHOL PRODUCTION - EHRLICH PATHWAY
-------------------------------------------------------------
Fusel alcohols are produced from amino acid metabolism via the oxo-acid pool.

PATHWAY: Amino acid -> (transamination) -> Oxo-acid -> (decarboxylation) ->
          Aldehyde -> (NAD+-dependent reduction) -> Fusel alcohol

KEY AMINO ACID / FUSEL ALCOHOL CORRESPONDENCES:
  Valine      -> alpha-Oxoisovaleric acid     -> Isobutyraldehyde  -> Isobutanol
  Leucine     -> alpha-Oxoisocaproic acid     -> Isovaleraldehyde  -> Isoamyl alcohol
  Isoleucine  -> alpha-Oxo-beta-methylvaleric -> 2-Methylbutanal   -> 2-Methylbutanol
  Phenylalanine -> Phenylpyruvic acid         -> (intermediate)    -> Phenethyl alcohol
  Tyrosine    -> Hydroxyphenylpyruvic acid    -> (intermediate)    -> Tyrosol
  Tryptophan  -> (intermediate)               -> (intermediate)    -> Tryptophol
  Alanine     -> Pyruvic acid                 -> Acetaldehyde      -> Ethanol

DUAL SOURCE: Oxo-acids are derived BOTH from:
  (a) Carbohydrate metabolism (de novo synthesis)
  (b) Transamination of wort amino acids

CRITICAL REGULATION:
  - Presence of an amino acid in wort may INHIBIT the corresponding fusel alcohol
    (feedback inhibition of the first enzyme in the biosynthetic pathway, e.g.,
    valine inhibits alpha-acetolactate synthetase)
  - BUT: amino acid in EXCESS of what yeast needs often leads to ELEVATED levels
    of the corresponding fusel alcohol
  - Fusel alcohol content is therefore related to the BALANCE of amino acids in wort

CONCENTRATIONS IN BEER (Table 22.9, mg/L):
  n-Propanol:        Stout 13-60;  Pale ale 31-48;  Brown ale 17-29;  Lager 5-10
  2-Methylpropanol:  Stout 11-98;  Pale ale 18-33;  Brown ale 11-33;  Lager 6-11
  2-Methylbutanol:   Stout 9-41;   Pale ale 14-19;  Brown ale 8-22;   Lager 8-16
  3-Methylbutanol:   Stout 33-169; Pale ale 47-61;  Brown ale 28-77;  Lager 32-57
  Phenethyl alcohol: Stout 20-55;  Pale ale 36-53;  Brown ale 19-44;  Lager 25-32
  Ethyl acetate:     Stout 11-69;  Pale ale 14-23;  Brown ale 9-18;   Lager 8-14
  Isoamyl acetate:   Stout 1.0-4.9; Pale ale 1.4-3.3; Brown ale 0.4-2.6; Lager 1.5-2.0

1.5 DIACETYL (VDK) METABOLISM
-------------------------------------------------------------
FORMATION:
  Pyruvate -> alpha-Acetolactate (by acetohydroxy acid synthetase, intracellular)
  alpha-Acetolactate is EXCRETED by yeast into the beer
  alpha-Acetolactate -> Diacetyl (NON-ENZYMIC oxidative decarboxylation, extracellular)

  Similarly: Pyruvate + alpha-oxobutyrate -> alpha-Acetohydroxybutyrate -> 2,3-Pentanedione

CONVERSION RATE: Only ~4% of acetolactate converts to diacetyl under normal
  beer conditions (freed of yeast)
  - Rate INCREASES with temperature
  - Rate INCREASES with exposure to air (in presence of yeast)
  - Cu2+, Al3+, Fe3+ ions accelerate the conversion

REDUCTION (CLEANUP):
  - Yeast CANNOT take up acetohydroxy acids directly
  - Yeast readily takes up and reduces diacetyl and 2,3-pentanedione to
    innocuous diols (butane-2,3-diol and pentane-2,3-diol)
  - Rate depends on: yeast strain, yeast age, storage conditions

DIACETYL REST: Warm conditioning at 20 deg C for 2-3 days after primary
  fermentation allows:
  1. Remaining alpha-acetolactate to convert to diacetyl
  2. Remaining yeast to reduce diacetyl to diols

THRESHOLD: >0.5 ppm diacetyl regarded as off-flavor in lager beers
  - More sensitive modern assessment: >0.15 ppm imparts buttery flavor,
    more noticeable in lagers than ales
  - Max VDK during Irish stout fermentation: ~0.6 ppm at 44 hr post-pitch,
    falling to ~0.1 ppm

TYPICAL LEVELS IN COMMERCIAL BEERS (mg/L):
  Barley wine: Diacetyl 0.11-0.40, Pentanedione 0.04-0.08
  Lager:       Diacetyl 0.02-0.08, Pentanedione 0.01-0.05
  Ale:         Diacetyl 0.06-0.30, Pentanedione 0.01-0.20
  Stout:       Diacetyl 0.002-0.07, Pentanedione 0.01-0.02

PROBLEM SOURCES: Respiratory-deficient "petite mutants" of yeast produce large
  quantities of diacetyl. Pediococcus (beer sarcina) infection causes diacetyl off-flavor.

1.6 DIMETHYL SULPHIDE (DMS) PRODUCTION
-------------------------------------------------------------
- DMS is a significant flavor contributor, especially in lagers
- MALT-DERIVED: Heat-labile precursor is S-methylmethionine (SMM)
- FERMENTATION-DERIVED: Yeast enzymatically reduces DMSO to DMS
  (NADP+-dependent reaction)
- DMSO comes from oxidation of DMS during kilning and wort boiling
- Conversion extent depends on: yeast strain, wort composition, fermentation temp
- KEY: Ale and lager worts contain similar DMSO levels, yet lagers have higher DMS
  because MORE DMS is produced at LOWER fermentation temperatures
- SO2 formed during fermentation: up to 10 mg/L

1.7 STEROL AND FATTY ACID SYNTHESIS - OXYGEN REQUIREMENTS
-------------------------------------------------------------
- Sterol synthesis requires molecular oxygen at MULTIPLE steps:
  - Squalene -> Lanosterol (mixed function oxidase, NADP+-dependent, requires iron)
  - Other pathway steps also use O2
- Unsaturated fatty acid synthesis also requires O2 (mixed function oxidase)
- Yeast's oxygen requirement for sterol synthesis EXCEEDS that for unsaturated
  fatty acid synthesis
- During fermentation, sterols become esterified once wort O2 is consumed

1.8 SHOCK EXCRETION
-------------------------------------------------------------
- Yeast in glucose solution rapidly releases amino acids, which are
  subsequently re-absorbed in 2-3 hours
- Does NOT occur in maltose solutions
- More pronounced with mature yeast cells
- Practical significance: may contribute to lag phase when mature yeast is
  pitched into worts with high glucose content

================================================================================
2. FERMENTATION MANAGEMENT
================================================================================

2.1 DISSOLVED OXYGEN REQUIREMENTS
-------------------------------------------------------------
DISSOLVED OXYGEN RANGES:
  - Top fermentation wort: 5-15 mg O2/L
  - Cylindroconical vessels:
    - 7.8 deg P (SG 1031) wort: can tolerate 8 mg O2/L
    - 11.9 deg P (SG 1048) wort: 4-5 mg O2/L sufficient (and controls foam)
    - No abnormal effects reported at 4 mg O2/L (strain-dependent)

OXYGEN AND FLAVOR:
  - Reducing O2 from 8 to 3 mg/L causes:
    - 2-4x increase in esters (ethyl acetate, isoamyl acetate, ethyl caproate)
    - 7x increase in acetaldehyde
  - O2 is consumed during lag phase for sterol and unsaturated fatty acid synthesis
  - Excessive O2 promotes yeast growth at expense of flavor character

2.2 PITCHING RATES AND ALPHA-AMINO NITROGEN
-------------------------------------------------------------
PITCHING RATES (Cylindroconical vessels):
  - SG 1036-1042 (9-10.5 deg P): 10 x 10^6 cells/mL
  - SG >1060 (>14.7 deg P): 15 x 10^6 cells/mL for equivalent fermentation time
  - Top fermentation: 0.15-0.30 kg/hL pressed yeast (0.5-1.0 lb/brl)

ALPHA-AMINO NITROGEN (FAN):
  - SG 1080 (19.3 deg P): 400 mg/L alpha-amino nitrogen allows 40-hr fermentation
  - SG 1036-1042 (9-10.5 deg P): ~150 mg/L achieves same 40-hr fermentation time

ZINC: Levels up to 0.08 mg/L may be necessary for satisfactory fermentations

YEAST AT RACKING (British ales): 0.5-2 million cells/mL; 0.5-1.0 deg P
  (2-4 gravity points) of fermentable carbohydrate left for secondary fermentation

2.3 FERMENTATION VESSEL GEOMETRY - CYLINDROCONICAL VESSELS
-------------------------------------------------------------
HISTORY: Nathan patented enclosed vertical cylindrical vessels with conical bases
  in 1908 and 1927. Claimed faster fermentation, dual use for fermentation+lagering,
  controllable by temperature and DO, easy CO2 collection.

SIZES IN USE:
  - Ireland (pre-1960): 5,200-11,500 hL (3,100-6,900 bbl)
  - Japan (from 1965): 1,000-4,000 hL (600-2,400 bbl)
  - USA (soon after): 4,700-10,600 hL (2,620-6,360 bbl)
  - Top fermentation typical: 165-412 hL (100-250 bbl)
  - Top fermentation largest single vessel built: 13,225 hL (8,016 bbl)
  - Cylindroconical typical: 3,000 hL (1,800 bbl) referenced for cycle times

MULTI-BREW FILLING: Large vessels accommodate many brews, filled over many hours.
  Choice exists regarding which brews receive yeast pitch and which receive O2.

DEEP VESSEL EFFECTS:
  - Hydrostatic pressure increases CO2 solubility at base (~0.5 vol/meter depth)
  - In deep vessels, yeast forms little top crop regardless of strain type
  - Foam production tends to be excessive; antifoams sometimes used
  - Lower O2 levels can control foam in higher-gravity worts

CYCLE TIMES (3,000 hL cylindroconical, ale):
  Single vessel system: fermentation + maturation in one vessel
  Two vessel system: separate fermentation vessel -> maturation vessel

  TWO-VESSEL ADVANTAGES: Better capacity utilization, faster/more uniform chilling,
    easier blending, better yeast separation
  TWO-VESSEL DISADVANTAGES: Higher beer losses, DO pickup during transfer,
    additional vessel/mains to clean, less flexible timing

2.4 OPEN vs. CLOSED FERMENTATION
-------------------------------------------------------------
OPEN FERMENTATION:
  - Traditional vessels: 2-4 m (6-13 ft) deep
  - Wooden vessels typically ~82.5 hL (50 bbl)
  - Yeast rises to top, removed by suction or skimming
  - First yeast crop: tends to be less attenuative
  - Last yeast crop: most attenuative
  - Brewer selects crop that attenuates rapidly AND separates well

CLOSED/ENCLOSED FERMENTERS:
  - Advantages: CO2 collection, reduced contamination risk, better hygiene,
    CIP (clean-in-place) capability, pressure control
  - Can accommodate both top and bottom fermentation

DROPPING SYSTEM: After 24-36 hr, fermenting wort transferred to second vessel.
  Advantages: (i) cold trub left behind, (ii) mixing and aeration

ROUSING: Circulating fermenting wort through pump and spraying over surface.
  Essential for strongly flocculating yeast strains.

2.5 TEMPERATURE PROFILES
-------------------------------------------------------------
TOP FERMENTATION (British ales):
  - Pitch at 15-16 deg C (59-61 deg F)
  - Allow to rise gently to 20 deg C (68 deg F), rarely to 22 deg C (72 deg F)
  - Cool to 14-15 deg C (57-59 deg F) by end of fermentation

LAGERING:
  - Begins at 5 deg C (41 deg F), drops to ~0 deg C (32 deg F)
  - Traditional lagering: several months
  - Modern warm conditioning ("diacetyl rest"): 20 deg C for 2-3 days

POST-FERMENTATION CHILLING:
  - Beer chilled to -1 to 1 deg C (31-34 deg F) via plate heat-exchanger
  - SG 1032-1048 beers: chill to 0 deg C to -1 deg C (32 deg F to 30.2 deg F)
  - Higher gravity beers: can chill to -2 deg C (28.4 deg F)

2.6 PRESSURE CONTROL
-------------------------------------------------------------
- Enclosed fermenters fitted with automatic CO2 pressure regulators
- Pressure controls: foam height, CO2 content, fermentation rate
- High pressure suppresses yeast growth and slows fermentation
- Gauge pressure in beer tanks: up to 2 bar (29 psig)

================================================================================
3. BEER STABILITY SCIENCE
================================================================================

3.1 HAZE FORMATION - COMPOSITION AND MECHANISMS
-------------------------------------------------------------
CHILL HAZE: Forms when beer cooled to 0 deg C; redissolves at 20 deg C
  - More serious for lagers (served colder)
  - Amount isolated: 1.4-8.1 mg/L (EBC collaborative studies)

PERMANENT HAZE: Does not redissolve
  - Amount: 6.6-14.6 mg/L initially; up to 44 mg/L during storage
  - Beer commercially unacceptable long before gravimetric measurement is feasible

HAZE COMPOSITION:
  - 45.5-66.8% protein
  - Principal amino acids on hydrolysis: glutamic acid, proline, arginine, aspartic acid
  - 20-30% anthocyanogens (polyphenols)
  - 5.7-9.7% lignin
  - 2-4% glucose plus trace pentoses (arabinose, xylose)
  - 0.7-3.3% ash (minerals)
  - Average mol. wt. of haze: ~30,000 (range 10,000-100,000)

METAL CONCENTRATION IN HAZE (vs. parent beer):
  - Copper, iron, aluminum: concentrated 4,000-80,000x
  - Lead, nickel, tin, vanadium, molybdenum: concentrated 1,000-4,000x
  - Manganese, calcium, magnesium: concentrated ~100x
  - Copper and iron most significant as oxidation catalysts

HAZE MECHANISM:
  - Protein + Polyphenol <-> (protein-polyphenol complex) [hydrogen bonding]
  - Hydrogen bonding = weak, reversible = CHILL HAZE
  - Oxidation -> covalent bonds = PERMANENT HAZE
  - Polyphenols polymerize during aging -> increased cross-linking capacity
  - Hydrophilic groups on proteins are blocked by polyphenol interaction
  - Condensed tannins (mol. wt. 700-1000) most effective at cross-linking

FOAM/HAZE PROTEIN OVERLAP: There is great overlap between haze-forming and
  foam-stabilizing proteins. Reducing proteolysis or boil time improves head
  retention BUT simultaneously reduces shelf life.

HAZE SCALES:
  - EBC: <30 = clear beer; >80 = unacceptable
  - 10,000 ASBC Formazin Turbidity units = 145 EBC Formazin Haze units
  - 1 EBC unit = 69 ASBC units

CALCIUM OXALATE HAZE: Separate mechanism; solubility = 6.07 mg/L at 13 deg C.
  Can form microcrystal hazes in beer.

BETA-GLUCAN HAZE: Beta-glucans responsible for viscosity have mol. wt. > 300,000.
  Beer beta-glucan content: 0.29-0.58%; stouts: 0.9-1.03%

3.2 FLAVOR STABILITY AND STALING
-------------------------------------------------------------
OVERVIEW: Flavor instability (not biological instability or haze) is now
  the primary determinant of shelf life for most beers.

STALING RATES (inversely proportional to):
  - Original gravity / alcohol content
  - Colored malt in grist / level of reducing substances (ITT)
  Therefore: Strong stouts = most flavor stable; Low-gravity lagers = least stable

STALING CHARACTERS BY BEER TYPE:
  - Stouts: develop stale, cheesy characteristics
  - Light lagers: develop sweet, papery/cardboard, metallic notes
  - Ales: develop distinctly sweet, molasses-type cloying characters
  - Positive characters (alcoholic, floral, malty, caramel, body) DECLINE

KEY STALING COMPOUND: 2-trans-nonenal (cardboard flavor)
  - Threshold: 0.11 ppb (extremely low)
  - Derived from linoleic acid via trihydroxyoctadecenoic acid
  - Also: 2-methylfurfural contributes to cardboard character

OXYGEN AND STALING:
  - ~1 mL air in a 300 mL bottle = ~1 ppm O2
  - 1 ppm O2 is probably sufficient to oxidize ALL reductones in a light lager
  - Dissolved O2 rapidly disappears without IMMEDIATE off-flavor formation
  - BUT: melanoidins and reductones act as oxygen CARRIERS, producing
    off-flavors at a later date
  - Overcarbonating does NOT reduce O2 uptake (O2 uptake is a function of
    partial pressure differential, not total gas content)

RIBES/CATTY TAINT:
  - Strongly correlated with headspace air
  - Develops rapidly over 6 weeks in high-air bottles, then slowly declines
  - Responsible compound: 4-mercaptopentan-2-one (threshold: 0.005 ppb water,
    0.05 ppb beer)
  - Beers with strong catty odors: 1.5 ppb mercaptopentanone

LIGHT-STRUCK FLAVOR:
  - 3-Methylbut-2-enyl thiol (prenyl mercaptan) at 0.1-1.0 ppb
  - Threshold: 0.005 ppb in water, 0.05 ppb in beer
  - Photolysis of iso-alpha-acids -> isoprenyl radicals + cysteine -> thiol

ANTIOXIDANT CAUTION:
  - SO2 and ascorbic acid sometimes added as antioxidants
  - BUT: In the presence of iron, ascorbic acid becomes a POTENT oxygen carrier

PASTEURIZATION AND FLAVOR:
  - Excessive pasteurization -> cooked, biscuity flavors
  - Especially when dissolved O2 > 0.3 mg/L
  - Effective pasteurization: 5-6 PU (when cell counts <100/mL)
  - Safety margin: 15-30 PU is the generally-used range
  - Standard temp: ~60 deg C (140 deg F) held for ~20 min
  - Tunnel pasteurizer: preheat 35-50 deg C (5 min), 50-62 deg C (13 min),
    60 deg C (20 min pasteurization), cool to 20 deg C at discharge

FURFURAL AND 5-HMF IN BEER:
  - 5-Hydroxymethylfurfural: 0.5-4.0 ppm typical (max 7.8 ppm; one dark
    German beer: 71.5 ppm)
  - Furfural: <15 ug/L normally; increases markedly during pasteurization
    and storage at 40 deg C (max found: 1843 ug/L)

3.3 ACETALDEHYDE IN BEER
-------------------------------------------------------------
  British lager: 2.3-28.2 ppm (mean 8.7)
  Foreign lager: 0-13 ppm (mean 1.1)
  Light and pale ales: 3.8-33.8 ppm (mean 8.2)
  Primed beers: 3.0-37.2 ppm (mean 15.2)
  Irish stout: 0.5-10 ppm (mean 4.0)
  American beers: 2-18 ppm (mean 9.1)

================================================================================
4. CARBONATION SCIENCE
================================================================================

4.1 CO2 SOLUBILITY AND HENRY'S LAW
-------------------------------------------------------------
- 1 volume CO2 = 0.196% CO2 by weight
- CO2 dissolving = function of time; rate decreases exponentially as
  equilibrium approaches
- Increase in pressure -> LINEAR increase in dissolved CO2
- Increase in temperature -> NON-LINEAR decrease in dissolved CO2
- Henry's Law: Concentration in liquid = imposed pressure / Henry's constant
  (Henry's constant is temperature-dependent)

HYDROSTATIC PRESSURE EFFECT: In deep tanks, dissolved CO2 at base is
  greater than at surface by roughly 0.5 vol/meter depth

SUPERSATURATION: Beer can hold CO2 in supersaturated state. Rapid pressure
  release does not cause immediate equilibration - this is why poured beer
  doesn't gush uncontrollably. Bubble nucleation requires suspended solids,
  container imperfections, or mechanical agitation.

SPECIFIC EXAMPLES (from Fig. 20.35):
  At 3 bar gauge pressure:
    - 15 deg C: 4 vol. CO2 equilibrium
    - 26 deg C: 3 vol. CO2 equilibrium
    - 41 deg C: 2 vol. CO2 equilibrium

KEG DISPENSE EXAMPLE:
  - Beer at 10 deg C, 2 vol. CO2 -> equilibrium pressure = 0.7 bar (10.5 psig)
  - If temp falls to 4.4 deg C at same pressure -> CO2 rises to 2.4 vol
    (difficult to dispense)
  - If temp rises to 15.5 deg C -> CO2 falls to 1.65 vol (uncontrollable foaming)
  - Additional pressure per horizontal meter of line: +0.011 bar
  - Additional pressure per vertical meter: +0.108 bar

HEAD-FORMING CAPACITY:
  - Normal CO2 range: 0.35-0.42% w/w
  - Within this range, CO2 content affects foam FORMATION but not foam RETENTION
  - Foams formed with CO2 collapse 4x faster than foams formed with air or nitrogen

4.2 NATURAL CONDITIONING AND KRAUSENING
-------------------------------------------------------------
- British ales: 0.5-1.0 deg P (2-4 gravity points) of fermentable carbohydrate
  left for secondary fermentation
- Krausen (actively fermenting wort) can be added to lagering vessel
- During lagering, CO2 produced purges air, H2S, and other volatiles from beer
- CO2 excess can be removed by bubbling oxygen-free nitrogen through beer

4.3 ARTIFICIAL CARBONATION
-------------------------------------------------------------
- Done during chilling operation (takes advantage of turbulence through plate
  heat-exchanger and low temperature)
- CAUTION: overcarbonation is difficult to reverse without creating fob
- To reduce CO2: bubble oxygen-free nitrogen through beer (best approach)
- It is CRITICAL not to exceed specification, as reducing is harder than adding

================================================================================
5. BEER CLARIFICATION
================================================================================

5.1 ISINGLASS FININGS
-------------------------------------------------------------
COMPOSITION: Dried swim-bladders of selected fishes, soaked in dilute tartaric
  and sulphurous acids for up to 6 weeks. Contains:
  (i) Solubilized collagen - the ACTIVE component
  (ii) Gelatin (denaturation product) - NOT effective
  (iii) Insoluble material - contributes to viscosity but not fining

MECHANISM:
  - Collagen molecules are positively charged at beer pH
  - React with negatively charged yeast cells, proteins, lipids, antifoams
  - Create BRIDGES between yeast cells, forming larger aggregates
  - Larger aggregates settle faster per Stokes' Law

COLLAGEN MOLECULE: Three coiled polypeptide chains forming rod of 1.5 nm diameter.
  Monomers 300 nm length, mol. wt. ~300,000

OPTIMAL CONDITIONS:
  - Best pH for fining: 4.4 (almost as good at 4.0)
  - Storage: 4-10 deg C (39-50 deg F)
  - Deteriorate seriously in few hours at 25-30 deg C (77-86 deg F)
  - Work POORLY if beer temperature is falling
  - Maximum yeast for effective fining: ~2 million cells/mL
  - Cations inhibit the reaction (higher valency = more inhibition)

EFFECTIVENESS MEASUREMENT: Intrinsic viscosity [eta] of finings in citrate solution
  - Easy beers: need [eta] > 16
  - Difficult beers: need [eta] > 20 (differences between isinglass types become apparent)

SECONDARY BENEFITS:
  - Improves foam stability by removing fats and foam-negative material
  - Finings themselves are foam-forming
  - Spares filter media (extends filter runs)

AUXILIARY FININGS: For beers that don't respond to isinglass alone.
  - Made from alginates, carrageenan, or silicic acid (negatively charged)
  - Added BEFORE isinglass to precipitate positively charged colloids
  - Flocs should ideally be separated before isinglass is added

5.2 GELATIN
-------------------------------------------------------------
- Derived from alkaline degradation of slaughter-house by-products
- Action similar to isinglass but SLOWER and LESS effective
- Requires ~5 days to clarify a large conditioning tank

5.3 PVPP (Polyvinylpolypyrrolidone / Polyclar / Agent AT)
-------------------------------------------------------------
- Insoluble polymer (mol. wt. > 700,000)
- Selectively adsorbs polyphenols (anthocyanogens) from beer
- Bonding between polyphenols and PVPP is similar to polyphenol-protein bonding
  (PVPP contains the amide/peptide linkage -CO.NH- found in all proteins)

DOSING AND EFFECTIVENESS:
  - 16 g/hL (1 oz/brl) at 36 deg F for 48 hr: removed 39% of anthocyanogens
    with corresponding increase in shelf-life
  - No loss of head retention (unlike some other treatments)
  - Substantial fall in oxidizable tannin value
  - No removal of particular proteins (isoelectric profile unchanged)

NYLON 66:
  - Also selectively adsorbs anthocyanogens
  - 138 g/hL (0.5 lb/brl): removed 30% anthocyanogens; shelf-life increased to
    200 days (fobbed bottles) or 40 days (bottles with 10-12 mL air)
  - BUT: also removed 17.5% of isohumulones and slightly depressed head retention
  - Nylon paste (larger surface area): 55 g/hL (0.2 lb/brl) removed 30%;
    333 g/hL (1.2 lb/brl) for 60%
  - Regenerated with 0.1 N NaOH

PVPP-INCORPORATED FILTER SHEETS: Commercially available. PVPP in sheet material
  adsorbs phenolics during filtration. Regenerated with 0.5% NaOH at ambient temp.

5.4 FILTRATION PRINCIPLES
-------------------------------------------------------------
KEY EQUATIONS:
  Darcy's Law: Q = phi * (P*A) / (L*M)
    Q = flow rate (mL/s), phi = permeability factor, P = pressure differential,
    A = filter area, L = filter thickness, M = viscosity

  Reducing capillary radius to 1/8 requires 4000x pressure increase for same flow

PRACTICAL NUMBERS:
  - Sheet filter standard: 60 x 62 cm (largest: 100 x 100 cm)
  - Sheet flow rates: 0.8-2.0 hL/m2/hr (depending on sheet retentivity)
  - Fine filter max pressure differential: 0.7 bar (to prevent forcing
    organisms through pores)
  - Filtration increases DO by 0.2 to 2 mg/L (a significant concern)
  - Beer clarity target: <0.5 deg EBC after filtration

KIESELGUHR (DIATOMACEOUS EARTH) FILTRATION:
  - Precoat slurry dosing: ~500 g/m2
  - Body feed: ~100 g/hL (0.36 lb/brl)
  - Two precoats: first coarse, then fine
  - Fresh surface presented as body feed builds up on precoat

FILTER TYPES:
  (i) Plate and frame
  (ii) Vertical leaf
  (iii) Horizontal leaf
  (iv) Candle or edge filters

5.5 CENTRIFUGATION
-------------------------------------------------------------
THROUGHPUTS:
  - Cylindrical bowl clarifiers (wort): up to 107 hL/hr (65 bbl/hr)
  - Self-cleaning clarifiers (beer): up to 600 hL/hr (370 bbl/hr)
  - Beer recovery from tank bottoms: up to 40 hL/hr (25 bbl/hr)

DISADVANTAGES:
  - Raises beer temperature by ~3 deg C (5 deg F) -- may require rechilling
  - High energy cost; excessive noise
  - Yeast recovered may be inferior for repitching
  - Complex, costly machines

ADVANTAGE: Hermetically sealed machines prevent CO2 loss and O2 uptake

================================================================================
6. FOAM / HEAD RETENTION
================================================================================

6.1 FACTORS INFLUENCING HEAD RETENTION
-------------------------------------------------------------
FOAM-POSITIVE FACTORS:
  - Proteins/peptides/polypeptides (larger molecules most important; mol. wt. > 12,000)
  - Glycoproteins from malt (tightly bound carbohydrate)
  - Iso-alpha-acids (concentrated in foam: 25 ppm in beer -> 93-120 ppm in collapsed foam)
  - Isohumulone > isocohumulone for head retention
  - Iso-alpha-acids responsible for foam adhesion/lacing (unhopped beer shows no lacing)
  - Traces of heavy metals (Fe, Co, Ni, Cu) improve head retention only in presence
    of iso-alpha-acids
  - Unmalted cereals (wheat, barley) improve head retention
  - In ales: protein present at ~4x the amount needed for reasonable foam
  - In lagers: protein only ADEQUATE for satisfactory foam

FOAM-NEGATIVE FACTORS:
  - Lipids (fatty acids, glycerides, phospholipids)
  - Dipalmitin > palmitic acid > monopalmitin in destroying head retention
  - Long chain fatty acids (from wort) more harmful than short chain (C6-C12, from fermentation)
  - Mixtures of phospholipids + triglycerides show massive foam-depressant activity
  - Only 1 ppm whole malt lipids causes loss in head retention
  - Antifoams
  - Detergent residues, grease on glassware

TEMPERATURE EFFECT ON FOAM:
  - Time for 10 mm collapse: 100 s at 15 deg C; 93 s at 20 deg C; 77 s at 25 deg C

BLOM HEAD RETENTION VALUES (half-life):
  - Excellent retention: >= 90 s
  - Poor retention: < 80 s
  Typical values: Pale ale (OG 1035): 75 s; Pale ale (OG 1055): 77 s;
  Brown ale: 77 s; Strong ale (OG 1080): 73 s; Sweet stout: 89 s

THROUGHOUT BREWING PROCESS:
  Wort: 115 s -> Beer at rack: 86-94 s -> Fined beer: 82-88 s -> Bottled (1 week): 79 s

GAS TYPE AND FOAM STABILITY:
  - CO2 foams collapse 4x FASTER than air or nitrogen foams
  - Mixed-gas (nitrogen widgets, stout) dramatically improve foam stability

================================================================================
7. PACKAGING SCIENCE
================================================================================

7.1 OXYGEN CONTROL IN PACKAGING
-------------------------------------------------------------
- Beer filled under gauge pressure up to 2 bar
- Excessive pasteurization with DO > 0.3 mg/L causes cooked/biscuity flavors
- Bottle evacuation or CO2 flushing before filling reduces headspace air
- Fobbing/jetting (ultrasonic or mechanical) displaces air above beer with foam
- ~1 mL air in 300 mL bottle = ~1 ppm O2 -- sufficient to oxidize all
  reductones in light lager

7.2 PASTEURIZATION
-------------------------------------------------------------
PASTEURIZATION UNIT (PU): 1 minute at 60 deg C (140 deg F)
  PU = time(min) * 1.393^(T-60)

  - 5-6 PU: reasonably effective when cell counts < 100/mL
  - 15-30 PU: generally used range (safety margin)
  - Most resistant normal contaminants: lactic acid bacteria and certain
    Saccharomyces spp. (e.g., S. pastorianus)

TUNNEL PASTEURIZER PROFILE:
  - First preheat: 35-50 deg C for 5 min
  - Second preheat: 50-62 deg C for 13 min
  - Pasteurization hold: 60 deg C for 20 min
  - Precool: 60-49 deg C for 5 min
  - Cool: 49-30 deg C
  - Discharge: 30-20 deg C for 2 min
  - Outputs: 2,000-60,000 bottles/hr
  - Can pasteurizers: shorter preheat/cool (cans tolerate thermal shock)

FLASH PASTEURIZATION: Beer pasteurized in bulk before packaging.
  - Around 8.5-10 bar gauge pressure with ~1 bar back pressure
  - Sterile filtration may substitute for pasteurization in some cases

HOT FILLING: Beer dispensed at 65 deg C (149 deg F) to sterilize bottle.

7.3 FILLING
-------------------------------------------------------------
- Modern fillers: up to 2,000 bottles/minute
- Counter-pressure filling: bottle pressurized to match headspace pressure of
  beer tank before beer delivery
- Long-tube fillers: deliver beer at base of bottle, air snifted from neck
- Short-tube fillers: beer flows down from holes near neck
- Beer in filling tank at gauge pressure up to 2 bar; constant level via float

SHELF LIFE FACTORS (summary):
  1. Dissolved oxygen at packaging
  2. Headspace air volume
  3. Original gravity / alcohol content (higher = more stable)
  4. Colored malt / reducing substance content
  5. Polyphenol-protein balance
  6. Metal ion content (especially Cu, Fe)
  7. Temperature of storage
  8. Light exposure (for hopped beers in clear/green glass)
  9. Pasteurization adequacy

================================================================================
8. PRACTICAL SYNTHESIS - KEY NUMBERS FOR HOMEBREWERS
================================================================================

FERMENTATION BYPRODUCT CONTROL SUMMARY:
  Want MORE esters (fruity): Lower O2 (3-5 mg/L), restrict growth, higher gravity,
    lower pitching rate, warmer fermentation, adequate FAN
  Want FEWER esters (clean): Higher O2 (8+ mg/L), promote growth, lower gravity,
    higher pitching rate, cooler fermentation

  Want LESS diacetyl: Allow diacetyl rest at 20 deg C for 2-3 days at end of
    primary; choose low-VDK yeast strain; avoid bacterial contamination

  Want LESS fusel: Moderate FAN (not excessive), adequate pitching rate,
    moderate fermentation temperature, balanced amino acid spectrum

  Want MORE glycerol (body): Natural byproduct at 1.5-3.4 g/L; higher in
    higher gravity beers; cannot easily be independently manipulated

CO2 CARBONATION REFERENCE:
  At equilibrium with pure CO2:
  - 0 deg C, 1 bar: ~3.5 vol
  - 5 deg C, 1 bar: ~2.8 vol
  - 10 deg C, 1 bar: ~2.3 vol
  - 15 deg C, 1 bar: ~2.0 vol
  (1 vol CO2 = 0.196% w/w = 1.96 g/L)
  - Pressure increases: linear increase in dissolved CO2
  - Deep vessel bonus: +0.5 vol per meter depth

CLARITY CHECKLIST:
  1. Cold condition at lowest safe temperature (-1 to 1 deg C) for minimum several hours
  2. Fining agents if needed (isinglass at pH 4.0-4.4; max 2M cells/mL)
  3. PVPP or silica hydrogel for polyphenol removal (extends shelf life)
  4. Filter at cold temperature (do not allow warming in filter)
  5. Minimize O2 pickup during all transfers and filtration
  6. Target clarity: < 0.5 deg EBC

SHELF LIFE ENHANCEMENT PRIORITY ORDER:
  1. Minimize O2 at ALL post-fermentation stages
  2. Cold condition to precipitate protein-polyphenol complexes
  3. Remove haze precursors (PVPP, silica gel, or tannic acid)
  4. Pasteurize or sterile-filter
  5. Minimize headspace air in package
  6. Store cold and dark

================================================================================
END OF EXTRACTION
================================================================================
