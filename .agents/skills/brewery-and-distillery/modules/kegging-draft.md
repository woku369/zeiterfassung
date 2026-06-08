# Kegging and Draft Systems

**Confidence**: High
**Last validated**: 2025-01-27
**Sources**: Northern Brewer, MoreBeer, HomeBrewTalk, BrewCabin, Beer Maverick, Kegerators.com, Renny's Draft Solutions, Brew Your Own, Craft Beer & Brewing, The Beverage People, Spike Brewing

---

## 1. Why Keg?

Kegging eliminates the most tedious part of homebrewing: bottling. Instead of cleaning, sanitizing, filling, and capping 50+ bottles, you transfer beer into a single vessel, carbonate it with CO2, and serve on draft.

**Advantages over bottling:**
- Faster packaging (one vessel vs. 50+ bottles)
- Forced carbonation in hours/days instead of 2-3 weeks bottle conditioning
- Precise carbonation control
- No sediment in the glass
- Easy to serve at parties and events
- Ability to purge with CO2 to minimize oxidation

**Disadvantages:**
- Higher initial cost ($150-400+ for a basic setup)
- Requires refrigeration space (keezer or kegerator)
- Less portable than bottles
- Not suitable for competitions (most require bottles)

---

## 2. Cornelius (Corny) Kegs

Cornelius kegs are repurposed soda industry kegs that have become the standard for homebrew draft systems. They hold 5 gallons and use quick-disconnect fittings for gas-in and liquid-out.

### Ball Lock vs. Pin Lock

| Feature | Ball Lock | Pin Lock |
|---------|-----------|----------|
| Height (5 gal) | ~25" | ~22" |
| Diameter | ~8.5" | ~9" |
| Fitting type | Ball bearing retainer | 2-pin (gas) / 3-pin (liquid) |
| PRV on lid | Yes | Typically no |
| Material | Stainless + rubber | Stainless + rubber |
| New availability | Widely available | Used only |
| Fitting confusion risk | Posts look similar | Distinct pin counts prevent misconnection |
| Originally used by | Pepsi | Coca-Cola |

**Ball lock** is the most popular choice for new homebrewers due to wider availability of new kegs, fittings, and accessories. Pin lock kegs are shorter (useful for tight spaces) but can only be found used.

### Torpedo Kegs

Torpedo kegs are modern all-stainless-steel ball lock kegs designed for homebrewers.

| Feature | Standard Corny | Torpedo (6 gal) |
|---------|---------------|-----------------|
| Construction | Stainless + rubber top/bottom | All 304 SS, laser welded |
| Stackable | No | Yes (any size on any size) |
| Diameter | 8.375" | 9.125" |
| Height | 24.75" | 27.25" |
| Serving while stacked | No | Yes (with fittings connected) |

Torpedo kegs cost more but offer superior durability, stackability, and the ability to serve while stacked — saving keezer space.

### Keg Anatomy

- **Lid**: Sealed with an oval gasket; contains pressure relief valve (ball lock)
- **Gas-in post**: Connects CO2; shorter dip tube (or no tube — gas enters headspace)
- **Liquid-out post**: Connects to faucet; long dip tube reaches keg bottom
- **Dip tube**: Stainless tube inside keg; liquid tube draws from bottom
- **O-rings**: Seal lid, posts, and dip tube connections; replace regularly
- **Pressure relief valve (PRV)**: Manual release; pull ring to vent excess pressure

---

## 3. CO2 Systems

### CO2 Tanks

CO2 tanks store liquid carbon dioxide under pressure. Most homebrew tanks are aluminum (lightweight, rust-proof).

| Tank Size | Approximate Kegs (5 gal) | Best For |
|-----------|--------------------------|----------|
| 2.5 lb | 7-11 | Compact setups, portability |
| 5 lb | 15-22 | Standard homebrew (most popular) |
| 10 lb | 30-44 | Multi-keg setups |
| 15 lb | 45-66 | High-volume, fits most kegerators |
| 20 lb | 60-88 | Best value per fill; may need external storage |

All homebrew CO2 tanks use the **CGA320** valve standard, making regulators interchangeable between tank sizes.

**Refilling:** Most local homebrew shops and welding supply companies can fill or exchange CO2 tanks. Tanks require hydrostatic testing (recertification) every 5 years.

### Regulators

The regulator steps down tank pressure (~850 PSI at room temp) to working pressure (typically 8-14 PSI for serving).

| Type | Description | Use Case |
|------|-------------|----------|
| Single-gauge | Shows output pressure only | Budget option |
| Dual-gauge | Shows tank pressure + output pressure | Standard; tells when tank is low |
| Secondary regulator | Mounts downstream, sets independent pressure | Different pressures for different kegs |
| Inline regulator | Small, attaches to gas line | Individual keg pressure control |

**Dual-gauge regulators** are recommended for most homebrewers. The tank gauge won't gradually decrease (CO2 remains liquid until nearly empty), but a sudden drop from ~850 to 0 PSI indicates the tank is empty.

### Manifolds

Manifolds split one CO2 line to serve multiple kegs from a single tank and regulator.

| Feature | Purpose |
|---------|---------|
| Individual ball valves | Turn off gas to specific kegs without affecting others |
| Check valves | Prevent beer from backflowing into gas lines |
| MFL (flare) fittings | Secure, leak-free connections (preferred over barbed) |

Available in 2-way through 6-way configurations. Individual valves allow you to disconnect a keg without depressurizing the entire system.

---

## 4. Line Sizing and Balancing

### Gas Lines

| Size | Use |
|------|-----|
| 5/16" ID | Industry standard for gas lines |
| 1/4" ID | Also common, especially with MFL fittings |

Gas line diameter is not critical for serving — CO2 pressure equalizes regardless of tubing size. Use whatever matches your fittings.

### Beer (Liquid) Lines

Beer line sizing is critical for proper pour quality. Too little resistance causes foaming; too much causes slow, flat pours.

**Standard homebrew beer line: 3/16" ID vinyl tubing**

Resistance per foot: ~2-3 PSI/ft (3/16" ID at 38°F)

**Line balancing formula:**
```
Required line length = (Serving PSI - Height factor) / Resistance per foot

Height factor = 0.5 PSI per foot of vertical rise (keg to faucet)
Resistance = ~2.2 PSI/ft for 3/16" vinyl at 38°F

Example: Serving at 12 PSI, faucet 1 ft above keg center:
Length = (12 - 0.5) / 2.2 = 5.2 ft
Use 5-6 ft of 3/16" beer line
```

**Troubleshooting pours:**

| Problem | Cause | Fix |
|---------|-------|-----|
| All foam, no beer | Lines too short, pressure too high, beer too warm | Lengthen lines, reduce PSI, check temp |
| Slow, flat pour | Lines too long, pressure too low | Shorten lines, increase PSI |
| Foam at start, then fine | Warm line near faucet | Insulate draft tower, use a fan |
| Beer goes flat over time | Slow CO2 leak | Check all connections with soapy water |

---

## 5. Forced Carbonation

Forced carbonation uses CO2 pressure to dissolve carbon dioxide directly into beer, replacing the natural carbonation that occurs during bottle conditioning.

### Carbonation Reference (Volumes CO2)

| Style | Target Volumes | PSI at 38°F |
|-------|---------------|-------------|
| British ales, stouts | 1.5-2.0 | 4-8 |
| American ales, IPAs | 2.2-2.6 | 9-12 |
| German lagers, pilsners | 2.4-2.8 | 11-14 |
| Hefeweizen, Belgian ales | 2.8-3.5 | 14-18 |
| Nitro stout | 1.0-1.2 | See Nitro section |

### Methods

**Set-and-forget (recommended):**
1. Chill beer to serving temperature (36-38°F)
2. Connect CO2 at desired serving/carbonation pressure (per table above)
3. Wait 7-14 days
4. Beer is carbonated and ready to serve at the same pressure

This is the most reliable method — no risk of over-carbonation.

**Burst carbonation (faster):**
1. Chill beer to 36-38°F
2. Set regulator to 30 PSI
3. Leave for 24-48 hours
4. Reduce to serving pressure (10-12 PSI)
5. Allow 1-2 days to equilibrate
6. Taste and adjust

**Shake method (fastest, least precise):**
1. Chill beer to 36-38°F
2. Set regulator to 30 PSI
3. Lay keg on side and rock/shake vigorously for 3-5 minutes
4. Listen for CO2 absorption (hissing from regulator decreases as beer absorbs gas)
5. Let settle 30-60 minutes
6. Set to serving pressure and taste
7. Repeat if under-carbonated

**Caution:** Over-carbonation is easy with burst and shake methods. Start conservatively and adjust upward.

### Carbonation Temperature/Pressure Chart

CO2 solubility increases at lower temperatures. At 38°F and 12 PSI, beer reaches approximately 2.5 volumes CO2 — appropriate for most American ales.

```
Temperature    8 PSI    10 PSI    12 PSI    14 PSI
32°F (0°C)     2.4      2.6       2.9       3.1
36°F (2°C)     2.2      2.4       2.6       2.9
38°F (3°C)     2.1      2.3       2.5       2.7
40°F (4°C)     2.0      2.2       2.4       2.6
45°F (7°C)     1.8      2.0       2.2       2.4
```

---

## 6. Keezer and Kegerator Builds

### Keezer (Chest Freezer + Collar)

A keezer is a chest freezer with a wooden collar added on top, converting it into a multi-tap draft system. This is the most popular homebrew draft setup.

**Why a collar?** Refrigerant lines run through the walls of chest freezers. Drilling holes for faucet shanks directly into the freezer would puncture them. The wooden collar provides a safe mounting surface.

**Collar construction:**
1. Measure the freezer top; subtract 1/8" for a snug fit
2. Cut 2x10 or 2x12 lumber (height depends on keg clearance and CO2 tank placement)
3. Join with miter cuts or butt joints; use wood glue + 2.5" screws
4. Drill 7/8" holes for faucet shanks through the front of the collar
5. Line inside with 1" rigid foam board insulation; seal gaps with spray foam
6. Set collar on freezer (glue optional — some prefer removable for future freezer replacement)
7. Reattach freezer lid on top of collar with original hinges

**Temperature controller (Inkbird ITC-308):**
- Plug-and-play: plug freezer into the "cooling" outlet, controller into wall
- Place temperature probe inside — submerge in a bottle of water or tape to a keg with insulation for stable readings (liquid thermal mass dampens air temperature swings)
- Set to 36-38°F (2-3°C) for serving
- Compressor delay: use a controller with 3+ minute delay to protect the compressor from rapid cycling

**Sizing guide:**

| Freezer Size | Kegs (approx) | Notes |
|-------------|---------------|-------|
| 5 cu ft | 2-3 ball lock | Tight fit; CO2 tank may go outside |
| 7 cu ft | 3-4 ball lock | Most popular size |
| 10 cu ft | 4-5 ball lock | Room for CO2 tank inside |
| 15 cu ft | 6-8 ball lock | Large; requires significant space |

### Kegerator (Converted Refrigerator)

A standard refrigerator converted for draft service. The draft tower mounts on top.

**Advantages over keezer:** Smaller footprint, built-in shelving for bottles
**Disadvantages:** Holds fewer kegs (typically 1-2), draft tower can warm beer (causing foam)

**Draft tower foaming fix:** Install a small computer fan inside the kegerator to circulate cold air up through the tower, or insulate the tower interior.

---

## 7. Nitro (Nitrogen) Draft

Nitrogen draft produces the creamy, cascading pour characteristic of Guinness and other nitro stouts.

### How Nitro Works

Nitrogen is approximately 1% as soluble as CO2 in beer. This allows high serving pressure (needed to push beer through a restrictor plate) without over-carbonating.

### Beer Gas

**Blend:** 75% nitrogen (N2) / 25% CO2 (sometimes labeled 75/25 or "beer gas")

Do not use:
- Pure nitrogen (no carbonation at all)
- 60/40 CO2/N2 ("draft gas" — this is for long-draw commercial systems, not nitro pour)
- Pure CO2 at 30 PSI (will massively over-carbonate)

Beer gas requires a **nitrogen regulator** — these have reverse-thread connections (CGA580) as a safety precaution to prevent interchange with CO2 regulators.

### Stout Faucet (Restrictor Plate)

The stout faucet contains a **restrictor plate** (sometimes called a sparkler) — a small metal disc with 5 tiny holes that forces dissolved gas out of solution, creating the cascading effect and creamy head.

Below the restrictor plate sits a **flow straightener** — a white plastic piece that reassembles the turbulent flow into a smooth pour.

The stout faucet is hinged for both pull (pour through restrictor) and push (bypass restrictor for topping off).

### Nitro Carbonation and Serving

| Parameter | Value |
|-----------|-------|
| Target carbonation | 1.0-1.2 volumes CO2 |
| Serving pressure | 25-30 PSI |
| Serving temperature | 38-42°F |
| Faucet | Stout faucet with restrictor plate |

**Process:**
1. Carbonate beer to 1.0-1.2 volumes CO2 (set-and-forget at ~5 PSI for 1-2 weeks at 38°F, or use a carbonation calculator)
2. Switch to beer gas (75/25 N2/CO2) at 25-30 PSI
3. Serve through stout faucet

### The Two-Part Pour

1. Pull faucet handle forward — fill glass to 3/4 full at a 45° angle
2. Let rest 60-90 seconds for the cascade to settle
3. Pull faucet handle again to top off — or push handle forward (bypasses restrictor) for a gentle fill to the brim

### Best Styles for Nitro

Nitro diminishes perceived hop bitterness and accentuates malt smoothness. Best candidates:
- Dry stout (classic)
- Sweet/milk stout
- Oatmeal stout
- English brown ale
- Porter
- Scottish ale
- Cream ale

Not recommended for highly hopped styles — the creamy mouthfeel and reduced bitterness perception work against the style's intent.

### Budget Alternative ("Nitraux")

If you don't have a nitrogen system, you can approximate nitro-style serving:
1. Carbonate to 1.0-1.2 volumes CO2
2. Temporarily increase CO2 pressure to 25-30 PSI for the pour only
3. Serve through a stout faucet (or standard faucet for less effect)
4. Immediately reduce pressure back to maintenance level (~5 PSI)
5. Vent excess pressure from headspace

This prevents over-carbonation while providing the high pressure needed for the restrictor plate.

---

## 8. Kegging Workflow

### First-Time Keg Setup

1. **Disassemble** keg completely (lid, posts, dip tubes, poppets, O-rings)
2. **Inspect** all parts; replace worn O-rings (food-grade silicone)
3. **Clean** all parts with PBW solution
4. **Rinse** thoroughly
5. **Reassemble** keg with lubricated O-rings (food-grade keg lube)
6. **Pressure test**: seal keg, pressurize to 30 PSI, spray connections with soapy water, check for bubbles (leaks)

### Kegging a Batch

1. **Clean and sanitize** keg (see cleaning-sanitation module)
2. **Purge keg with CO2**: seal empty sanitized keg, pressurize to 10-15 PSI, vent through PRV, repeat 3-5 times (displaces oxygen)
3. **Transfer beer**: rack from fermenter through liquid post (closed transfer) or through open lid
4. **Seal and purge headspace**: pressurize to 15 PSI, vent PRV, repeat 2-3 times
5. **Chill** to serving temperature (36-38°F)
6. **Carbonate** using preferred method (set-and-forget recommended)
7. **Connect draft line** and serve

### Closed Transfer (Minimizing Oxidation)

For oxygen-sensitive styles (NEIPA, pale ales):
1. Purge keg with CO2 (multiple cycles)
2. Connect gas line to fermenter's gas post or spunding valve
3. Connect liquid transfer line from fermenter to keg's liquid post
4. Push beer from fermenter to keg using low CO2 pressure (2-5 PSI)
5. Beer never contacts air

---

## 9. Maintenance

| Task | Frequency |
|------|-----------|
| Replace keg O-rings | Annually or when leaking |
| Clean beer lines | Every 2 weeks minimum |
| Replace beer lines | Annually |
| Leak test connections | Each time keg is changed |
| Clean faucets | Every keg change |
| Check CO2 tank hydrostatic date | Every 5 years |
| Clean drip tray | Every 1-2 days |
| Defrost keezer | As needed (chest freezers rarely need it) |

### Leak Detection

A slow CO2 leak can empty a tank overnight. Apply soapy water to every connection and look for bubbles:
- Tank-to-regulator connection
- Regulator-to-gas-line connection
- Gas-line-to-manifold connections
- Gas disconnect-to-keg post
- Keg lid gasket
- Liquid post O-ring

---

## References

- Northern Brewer. "Nitro Beer 101: How to Set up Equipment for Serving Homebrew on Nitro." northernbrewer.com
- Kegerators.com. "CO2 Tank Guide." kegerators.com
- Renny's Draft Solutions. "CO2 Tank Sizes: Draft Dispensing Guide." rennysdraftsolutions.com
- BrewCabin. "How to Build a Keezer for Homebrewing." brewcabin.com
- Beer Maverick. "25 Beautiful DIY Keezer Build Designs." beermaverick.com
- Brew Your Own. "Nitrogen Draft Tap." byo.com
- Craft Beer & Brewing. "Nitraux: Pour Nitro-style on the Cheap." beerandbrewing.com
- The Beverage People. "Nitrogenate Your Homebrew." thebeveragepeople.com
- HomeBrewTalk forums. Various kegging, keezer, and CO2 discussion threads. homebrewtalk.com
