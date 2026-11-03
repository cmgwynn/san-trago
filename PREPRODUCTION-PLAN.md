# San Trago: Preproduction and Development Plan

Status: Stage 1 direction approved by the project owner on 2026-11-02.
Stage 2 walkthrough and Stage 3 screen storyboard drafted for review.
Stage 4 disposable Godot interaction lab implemented; human comparison pending.
Stage 5 hypothetical workload/economy worksheet implemented; calibration pending.
Full production is not authorized by this experiment.
Follow-up service-context experiment retested successfully by the project owner.
Equipment-preset comparison implemented; human upgrade review pending.

Working title: San Trago. Setting: the fictional coastal city of Sol Diego.

## 1. Purpose and approval

This is the shared source of truth for scope, design decisions, collaboration,
and the conditions for starting production. It replaces the earlier feature-led
roadmap.

Decisions explicitly approved by the project owner are recorded below. Other
recommendations remain provisional. The second creator should review the design
contract before the preproduction exit gate; their approval is not assumed.

Preproduction permits disposable interaction experiments and a minimal technical
foundation. It does not authorize building the full game. Production begins only
after the preproduction exit gate is met.

## 2. Game definition

### Player fantasy

Build a welcoming coastal neighborhood bar, become a capable hands-on bartender,
and turn a shabby dive into a place that feels like yours.

### Gameplay hierarchy

1. Primary experience: satisfying hands-on bartending.
2. Supporting challenge: managing a busy, readable counter.
3. Long-term motivation: improving and personalizing the bar.

Management changes the conditions of service. It is not initially a separate,
deep business simulation.

### Design pillars

- Personal transformation: upgrades and decor visibly change the bar.
- Busy hands, forgiving consequences: prioritize tasks, recover from mistakes,
  and understand why something happened.
- Meaningful equipment: purchases change workflow rather than only increasing
  numerical income.

### Scope guardrails

- Desktop, single-player, 2D, fixed-view workstation.
- Mouse-first; no walking character or camera scrolling in the first slice.
- Initial release targets macOS and Windows, with mouse/keyboard controls only.
- Default pressure is cozy with short rushes and comfortable recovery.
- No fluid physics, multiplayer, or simulation of multiple operating venues.
- Charming repetition must remain enjoyable after many orders, not just once.
- Systems should support authored content without requiring a bespoke script
  for every drink or customer.

## 3. Design decisions and remaining hypotheses

The project owner approved the core direction, first-slice scope, platform/input
targets, default pressure, and early economy/checkpoint rules on 2026-11-02.
Detailed implementation and tuning remain subject to the preproduction gates.

| Topic | Initial rule | Revisit when |
|---|---|---|
| Engine | Godot 4.x with GDScript; pin one stable version | Stage 6 workflow trial fails |
| Platforms/input | macOS and Windows; mouse/keyboard only for initial release | A later release explicitly expands support |
| Normal-mode pressure | Cozy with short rushes and comfortable recovery | Observed play differs from the intended experience |
| Authoring | Inspector-editable Resources and reusable scenes | Actual authoring exposes repeated friction |
| View | Fixed counter with limited service spots | First slice is proven |
| Drink quantities | Discrete measured units | A tested mechanic needs greater precision |
| Ingredient order | Does not matter initially | A specific, clearly taught recipe needs it |
| Drink quality | Explicit recipe validation, not a hidden score | Core preparation is readable and reliable |
| Decor | Fixed slots; mostly cosmetic | Free placement has a justified gameplay benefit |
| Ingredients | Available without stock limits; charge for quantities used | Economy and service loop are proven |
| Financial failure | No debt, rent, or bankruptcy | A later design explicitly needs them |
| Tips | Bonus for service, not necessary to cover a normally served order | Economy tests demonstrate a reason to change |
| Saving | Persist completed-day state and prep purchases; no mid-shift resume | Longer shifts justify more granular saving |
| Pressure | Authored waves with recovery periods | Playtests establish a better pacing model |
| Accessibility | Relaxed pressure, pause, readable feedback, input alternatives | Expand continuously through testing |

HTML, CSS, and JavaScript are not a second application layer. The requested
frontend/content/logic separation is implemented using Godot equivalents.

## 4. Player experience and operational rules

### Afternoon

1. Show previous results and available cash.
2. Let the player inspect equipment, menu, and decor.
3. Allow purchases and cosmetic choices without time pressure.
4. Persist successful purchases.
5. Let the player explicitly open the bar.

### Night

1. Quiet opening introduces the available work.
2. A small rush tests the basic preparation loop.
3. A recovery period lets the player clean and regroup.
4. A busier rush tests prioritization.
5. Closing stops arrivals, then resolves the remaining service.
6. Results explain sales, tips, waste, and profit.

Exact shift duration, service-spot count, patience values, and closing grace
period are tuning decisions established through experiments, not architectural
constants.

### Workstation information

- Customer spots and readable orders across the upper area.
- Central preparation area showing the selected glass and its contents.
- Consistently grouped ingredients and tools.
- Clearly distinguishable clean, dirty, and washing glasses.
- Secondary but visible cash and shift progress.
- Feedback that does not hide essential controls.

Produce low-fidelity screens before finalizing layout. These positions are
starting hypotheses, not a final UI specification.

### Service rules

- Core sequence: select glass, add ingredients, prepare, choose recipient, serve.
- Correct orders produce payment and an explained tip outcome.
- Wrong drinks are rejected with a specific reason and no revenue.
- Rejected drinks remain available to correct, serve elsewhere, or discard.
- A departing customer's unfinished drink remains available to the player.
- A compatible completed drink may satisfy another order.
- Discarding a drink loses its consumed ingredients and makes its glass dirty.
- A served glass remains with the customer until they finish; then it is dirty.
- No glass breakage in the first slice.
- Washing must remain available when no clean glasses remain.
- Transactions validate before changing state; failures explain their cause.

### Closing, interruption, and recovery

- Closing stops arrivals and repeat-order creation.
- Existing customers receive a visible, bounded closing grace period.
- At grace expiry, unserved orders end without payment or an extra closing
  penalty; completed sales remain counted.
- At final close, customer-held glasses return dirty and prepared drinks become
  waste. Record this explicitly in results.
- Between days, reset glasses to clean; the first slice has no paid overnight
  cleaning or persistent unfinished drinks.
- Pause freezes patience, arrivals, equipment, and shift progression together.
- Shop access is limited to afternoon; settings and pause remain available.
- Mandatory tutorial reading freezes service pressure.
- Do not add optional dialogue that forces players to lose orders while reading.
- Leaving mid-shift warns that the shift will restart from its opening checkpoint.
- A completed shift commits its results once; reopening cannot award them again.

### Glass invariant

Total owned glasses equals:

clean + in preparation + with customers + dirty + washing.

Serving, discarding, abandonment, washing, closing, and loading must preserve this
total. Only an explicit purchase changes the number owned.

## 5. Economy, upgrades, decor, and snacks

### Initial economy

Shift profit = sales + tips - ingredients consumed - explicit operating costs.

- Count ingredients in served, discarded, and unfinished drinks.
- Do not introduce wages or recurring expenses before those systems exist.
- For the initial unlimited-supply model, settle ingredient expenses in shift
  results. Cap the charge at available funds so cash cannot become negative;
  show any waived expense explicitly rather than hiding it.
- If waivers are frequent, adjust prices and costs before adding more content.
- If stock purchasing is introduced later, distinguish cash spent acquiring
  inventory from the cost of inventory consumed; do not charge twice.
- Starting hypothesis: a learning player can afford a modest improvement after
  about two successful shifts.

### Initial purchase choices

- Extra glasses provide a buffer during rushes.
- A dishwasher replaces active scrubbing with loading and batch-cycle timing.
- Fixed-slot decor provides visible expression.

At least two purchases must be plausible first choices. Tune equipment prices
and benefits using observed play, not a predetermined mandatory upgrade order.
The dishwasher must not remove glass planning entirely.

Decor must not make one aesthetic financially mandatory. Start with cosmetic
choices; introduce at most one visible atmosphere effect only if it can be
explained and tested. No hidden stack of tip multipliers.

### Peanuts

- Customers explicitly order peanuts.
- A satisfied snack customer may request at most one additional drink.
- That customer continues occupying their service spot.
- Repeat orders are not guaranteed and cannot generate further repeats.
- Explain the behavior in the interface.
- No continuous thirst simulation.

Repeat orders are conditional scope: enable them only after baseline service
and pacing are stable.

### Complete-day walkthrough: Stage 2 review draft

This walkthrough applies the agreed direction without assigning untested prices,
timers, or final interaction gestures. It is a reviewable specification, not a
claim that the walkthrough has been playtested or approved by both creators.

| Step | Player action and visible feedback | State and accounting outcome |
|---|---|---|
| 1. Begin afternoon | See cash, equipment, menu, and a clear Start Shift action | First day uses starting values; later days load the latest completed-day checkpoint |
| 2. Inspect purchases | See price, effect, ownership, and affordability before buying | Inspection changes nothing; buying requires validation |
| 3. Buy or skip | Successful purchase updates cash and equipment; rejected purchase explains why | Apply purchase once and save the new prep state; failure leaves the purchase unapplied |
| 4. Open bar | Confirm readiness and see the service workspace | Save opening checkpoint, initialize clean glasses, then begin service |
| 5. Receive first guest | Order card names the drink and shows patience using text/icon cues as well as color | Guest occupies one free service spot; opening arrivals are deliberately gentle |
| 6. Start a drink | Select a clean glass; see its contents as ingredients are added | Move one glass from clean to preparation; record each ingredient consumed |
| 7. Prepare and serve | Required method is visible; choose the recipient and receive specific validation feedback | A valid drink moves to the customer; record its sale once and explain its tip |
| 8. Fulfill peanuts if ordered | Snack requirement remains readable until served | Record snack sale and consumption once; baseline slice does not generate repeat orders |
| 9. Return the glass | Customer finishes; dirty-glass indicator updates | Move the glass from customer-held to dirty; free the service spot after departure |
| 10. Clean and regroup | Wash manually, or load an owned dishwasher and see its cycle state | Dirty glasses move through washing to clean; the same glass cannot enter two operations |
| 11. Handle a short rush | Several readable orders compete for attention, followed by recovery time | Arrival pacing changes, not the underlying service rules |
| 12. Close arrivals | Announce last service and show the closing grace period | Stop new customers and repeat orders; allow existing orders to resolve |
| 13. Finish service | Explain unfinished orders and discarded preparation | Return remaining glasses, account for waste, and calculate the final result once |
| 14. Review results | Show sales, tips, consumed ingredients, waste, expenses, and any waived costs | Commit completed-day results and next afternoon state together |
| 15. Continue or leave | Continue to prep or return later | Restart loads completed progress, not an already-paid results transaction |

#### Exception walkthroughs

- Wrong drink: show the missing, excess, or incompatible component. Do not
  charge the guest, destroy the drink, or consume a second glass. The player
  can correct it where possible, serve it elsewhere, or discard it.
- Guest leaves: remove the unpaid order and free the spot. A drink still on the
  workstation remains there. Do not refund ingredients already consumed.
- No clean glasses: clearly identify the bottleneck and keep washing reachable.
  Never invent a clean glass as an error fallback.
- Cannot afford a purchase: show the price and shortfall; leave cash, ownership,
  and save state unchanged.
- Pause: freeze every service timer and show that the game is paused. Resuming
  does not produce a burst of elapsed-time updates.
- Quit during service: explain that unfinished shift progress will be lost.
  Resuming restores the opening checkpoint, including prep purchases but not
  abandoned-shift revenue or ingredient charges.
- Save failure: show that progress was not saved and offer retry. Do not show
  "saved" or silently overwrite an earlier checkpoint. The precise recovery UI
  is a Stage 3 design task.
- Closing with unfinished work: explain waste and unpaid orders before final
  settlement; no invisible penalty or duplicated revenue.

#### Review checklist before closing Stage 2

- Both creators can trace one glass and one payment through the entire day.
- Failure feedback preserves enough information to choose a recovery action.
- The shop, service, and results screens agree about money and ownership.
- Agree that wrong-order rejection and opening-checkpoint restart fit the
  intended forgiving experience.
- Confirm results breakdown and saving/error messages in the screen storyboard.
- Leave recipe gestures, exact prices, patience, capacity, and wave duration
  explicitly open for experiments rather than guessing them here.

## 6. First vertical slice

### Committed content and features

- Pacific Pour: one fixed-view coastal dive bar.
- Afternoon, service, closing, results, and next-day loop.
- Draft beer and one simple mixed drink.
- One initial glass type compatible with both starter drinks.
- Peanuts as a simple served item, not a cooking system.
- Limited customer spots and a few reusable customer appearances.
- Clean/dirty glass inventory, manual washing, and a batch dishwasher.
- Extra-glass purchase as an alternative equipment investment.
- A few fixed-slot cosmetic options.
- Readable introduction, settings, relaxed pressure, and pause.
- Checkpoint saving and exported desktop builds.

### Conditional scope

- Hold-to-pour and drag-to-serve interactions.
- Atmosphere effects, snack repeat orders, named regulars (a guest-book
  prototype exists; see Stage 3), more glass types, and ingredient purchasing.

Add these only when they strengthen the tested loop without preventing its
completion.

### Explicitly deferred

- Freeform furniture placement and pathfinding-heavy interiors.
- Staff hiring and cooking.
- Branching narrative and large dialogue libraries.
- Complex cocktail chemistry, dynamic pricing, debt, and rent.
- Multiple active venues, multiplayer, and Steam-specific integrations.

## 7. Preproduction stages

Work in dependency order. Do not assign calendar estimates until interaction
experiments and a complete shift provide evidence of the team's production pace.

### Stage 1: Approve the design contract

Owners: both creators.

- Review the fantasy, hierarchy, pillars, scope, and provisional decisions.
- Confirm initial desktop test platforms based on available hardware.
- Decide whether controller support is a release requirement before finalizing
  workstation navigation; the first experiment remains mouse-first.
- Agree on desired pressure and acceptable consequences.
- Confirm responsibilities and the change-review workflow.

Exit gate: both creators independently describe the same first playable game.
Record unresolved questions rather than treating silence as approval.

### Stage 2: Walk through a complete day

Owners: both; systems lead records state rules, creative lead checks feedback.
Depends on Stage 1.

- Storyboard prep, opening, orders, preparation, payment, glass return, washing,
  closing, results, purchasing, saving, and reopening.
- Include wrong drinks, abandonment, no clean glasses, rejected purchases,
  unfinished work at closing, and quitting.
- Define every essential transition and player-facing explanation.

Exit gate: no essential transition is left as "figure it out in code."

### Stage 3: Specify screens and visual direction

Owner: creative lead, with systems review.
Depends on Stage 2.

Review artifact: [Pacific Pour screen storyboard](docs/screen-storyboard.html).
Open it in a browser. It is a static review document, not a playable prototype
or a change from Godot to a web-based game. Review screens by their numbers.
Includes prep, service, correction, washing, closing, results, pause/settings,
and save-recovery states. Counts, recipes, and financial examples are illustrative.

Candidate desktop layout checks: 1280 x 800 primary and 1024 x 768 smaller
window. These are review targets, not minimum system requirements. Browser
layout validation does not replace Godot UI testing.

Browser check on 2026-11-02: the storyboard opened successfully at both candidate
sizes with no horizontal page overflow, horizontally clipped cards, or broken
in-page links. Service layout was visually inspected. The annotated document
scrolls vertically; fitting the actual service controls into one game viewport
remains an interaction-prototype requirement, not a passed acceptance test.

Visual concept 01, 2026-11-03: [Bright day at Pacific Pour](docs/visual-concept.html).
The owner chose a front-on view from behind the bar, a cozy Stardew-like pixel style,
a bright daytime surf-shack mood, and a "very San Diego" setting. The concept is one
original, code-drawn service screen (320 x 200 native, x4 to 1280 x 800) showing Mode C
mid-pour, plus a palette, readability rules, and production implications. It is a
proposal: the creative lead's review and the open questions listed in the
concept remain outstanding, and it is not final art or an approved asset list.
The same page adds screen 2, an end-of-shift results screen at sunset. It reuses the
service-screen background with a palette swap and stress-tests the 5 px font on the
most text-heavy screen. Its numbers are illustrative, not taken from the balance worksheet.

Visual concept 02, 2026-11-03: [Golden hour at Pacific Pour](docs/visual-concept-02.html).
At the owner's request, this alternative takes inspiration from the mood of Strange Antiquities
without copying its assets: painted rather than pixel art, warm lamp-lit shelves,
and a symmetrical counter where the guest is framed in a tiled arch with a sunset sea behind.
It adds Churro, a bar cat you can pet, and a guest book that unlocks facts about
regulars as you serve them. The guest book would be a new system to design. Concept 01 and concept 02 are
competing proposals, so the creative lead should compare them or blend them before any art production starts.
Layout pass, same day: the screen now has fixed zones, and nothing overlaps the guest's face.
Orders are tickets on a brass rail, so a rush is one guest in the arch plus a queue of tickets.
The guest book is a glowing book on the lower shelf. Screen 2 opens it as an overlay that pauses service, but whether it should pause is still an open question.
Screen 3, "last call", is the painted end-of-shift results screen. It gives money and
"tonight's stories" equal space, so new guest-book facts are celebrated there too.

Layout lab, 2026-11-03: [layout_lab.tscn](scenes/layout_lab.tscn) is a gray-box of
the concept 02 zones in Godot, at 1600 x 900 letterboxed. Its tests check zone and
control overlap, keeping the guest's face clear, and fit at 1024 x 768, 1280 x 800,
1920 x 1080, and ultrawide. It is disposable: it validates layout and the
guest-book loop, not art or service pacing.

Layout pass 2 (genre review), 2026-11-03: after comparing the layout with Strange
Antiquities, Coffee Talk, VA-11 Hall-A, Papa's games, Good Pizza Great Pizza, Cook
Serve Delicious, and Bear and Breakfast, concept 02 and the layout lab were updated:
1. The glass is 2-3x larger, on a bar mat centered under the guest.
2. A labeled speed rail (draft, rum, cola, nuts, and an upgrade slot) with hotkeys 1-4.
3. Sink, washer, and dirty glasses share one back-bar strip that a hired busser can take over later.
4. A serve payoff beat (new screen 1b): reaction, coins to the tip jar, a ticket stamp, and a guest-book toast.
5. Recipe blocks have part letters and tick off as they're poured.
6. Duplicates were removed. The book opens only from the counter (or Tab), and the hint is a tutorial tag beside the glass.
7. Everything clickable has a brass plate and hover glow; decor is dimmed.
8. Waiting guests sit in shadow at the ends of the bar.
9. Regulars leave keepsakes on the shelves.
10. Text is at least 15 px (12 px on Steam Deck), with a controller cursor path planned.
Open for the creative lead: how visible waiting guests should be, and what keepsake each regular leaves.

Guest book system (prototype, pending creative-lead approval):
- Content: each [guest](content/guests/) has an ordered list of facts. A fact unlocks
  after N visits, N perfect serves, N serves of a drink ID, or one small-talk topic.
  It can also require an earlier fact. Topic facts need an authored hint; other locked
  facts generate a countdown hint ("Visits 2 more times").
- Rules: gameplay reports events and [guest_book.gd](scripts/systems/guest_book.gd)
  owns all progress. Facts unlock once, in authored order, and a chain can resolve in one
  event. New facts stay unread until their page is viewed.
- Saves are versioned. Facts removed from content are dropped with a warning, and newly
  authored facts that are already earned unlock on load.
- Guest content now holds each guest's usual drink and small-talk topics (an ID
  plus a line), and validation rejects a topic fact whose topic the guest never brings up.
- Scope: named regulars are conditional scope in section 6. This prototype does not add
  the guest book to the committed slice. If it's approved, the open questions are small
  talk (how topics are offered), whether the book pauses service, and how many facts
  per guest the slice can afford to write.

- Sketch service, selected order, drink preparation, rejection feedback,
  washing, shop, pause, and results.
- Establish a warm coastal palette, consistent perspective, readable
  silhouettes, and interactive-object contrast.
- Choose a primary desktop layout and a smaller-window layout test.
- Use reference material for direction, not copied assets.
- Avoid producing a full asset library.

Exit gate: every action has an identifiable control and visible outcome,
including paused, unavailable, and error states.

### Stage 4: Test two disposable interaction approaches

Owners: systems lead implements; creative lead directs interaction and feedback.
Depends on Stage 3.

The project owner's instruction to continue authorizes a disposable implementation
using the draft screens; it does not imply second-creator approval or completion
of Stages 2 and 3. Those reviews remain open.

Implementation: [Bartending Lab setup and comparison procedure](README.md).
Godot is pinned to 4.7.2. All modes use the same ten-order sequence, and
export local trial timing, incorrect-serve, discard, and hold-usage measurements.
The lab deliberately uses an instantly returned test glass and excludes the
customer, washing, economy, and progression systems. It does not validate those
systems or prove bartending is fun without human testing.

#### First playtest feedback and authorized follow-up

On 2026-11-02 the project owner preferred holding over clicking: slower but more
satisfying. Resetting incomplete pours on release was frustrating; strict beer /
rum-cola alternation felt repetitive. This is one qualitative report, not a
completed counterbalanced study or proof of the final interaction.

The project owner authorized a third experiment: drag a selected glass onto a
station, with tap-to-dock as an alternative, then hold the station to pour.
Release preserves fractional fill. The player stops within a visible generous
target window, and overpouring remains possible.

Mode C implements that experiment. Dropping or tapping only docks; a fresh hold
starts pouring. Each ingredient retains its own quantity through switching and
pause. The initial test tolerance is +/- 0.25 units for required ingredients,
with no allowance for incorrect ingredients and no automatic target cutoff.
This tolerance is a test hypothesis, not approved final balance. The glass is a
draggable button token, not final glass art or a fully spatial workstation.

Modes A/B remain unchanged input references. All modes now share a fixed,
non-alternating ten-order sequence with five of each starter drink. Exports
record protocol/schema changes, actual served quantities, and docking methods.
Do not treat prior alternating-order results as directly equivalent.

Additional comparison: B versus C, with test order reversed for the next tester.
Ask whether retaining fill feels better, whether docking feels natural, and
whether the target window is comfortably readable. Since C changes several
variables, ask which change helped rather than claiming it proves causation.
On 2026-11-02, after trying C, the project owner reported enjoying it and feeling
it combined the best aspects of the options. Carry C forward as the working
interaction for the next scoped experiment; retain A/B as reference modes.
This is qualitative preference evidence from one creator, not a measured
performance result or final approval by both creators. Second-creator feedback,
target-window tuning, and repeatability remain open. See the
[updated controls and protocol](README.md#what-to-try).

Follow-up experiment: test C alongside three customer service spots and
manual glass washing, with gentle scheduled arrivals and pause. Measure whether
docking, partial-fill recovery, and overpour feedback remain readable when
attention is divided. Keep shop, staff, neighborhoods, and progression out.
The owner's subsequent instruction to continue authorized this bounded
experiment, now available as [service_lab.tscn](scenes/service_lab.tscn).
The original interaction lab remains the default project scene.

Initial service hypotheses: four glasses, eight arrivals across two minutes,
sixty-second patience, ten-second drinking, three-second manual washing, and a
maximum twenty-five-second closing grace period. Manual washing occupies the
player's hands while customer timers continue. Pause/focus loss and confirmation
dialogs freeze the complete simulation. Missed arrivals are counted explicitly;
there is no hidden waiting queue. No money, shop, dishwasher, snacks, persistent
progress, or service-run export is implemented. These are scoped experiment
exclusions, not removal from the intended first slice.

Verification: service tests passed 32 scenario/layout checks plus 3,000
per-tick glass-invariant checks; the native macOS run also passed its viewport
capture check. Existing 78 lab and 33 balance checks passed unchanged.
Native service rendering was inspected at the primary size and automated bounds
checked both target sizes. Human workload, enjoyment, Windows, packaged builds,
and balanced upgrade choices remain unverified. This does not close the
preproduction exit gate or authorize the full production roadmap.

#### Service playtest and selection correction

The project owner reported on 2026-11-02 that service felt good and pacing was
reasonable, but target bars and selection were inconsistent after selecting a
glass or docking. Preserve the current pacing pending more evidence.

Review reproduced a stale-recipient problem: selection remained on a drinking
guest or vacant spot, and the service controller erased target markers even
when preparation was in progress. The correction separates the preparation's
recipe reference from the serving recipient, tracks guest identity rather than
only spot index, and selects the next waiting order automatically when there is
no established preparation to preserve.

Docked preparation retains target bands through departures, washing, and spot
reuse. Explicitly selecting another waiting guest retargets the recipe without
deleting liquid. Drinking/empty spots cannot be selected as orders; serving
requires a waiting recipient and glass. Missing-glass/order instructions replace
misleading empty target bars. Manual washing explains its hand lock and completion.
Substepped service processing prevents long frames from pouring past closing.
These are interaction consistency fixes, not a change to the tested pacing.

Verification after the corrections: 67 service scenario/UI/layout checks and
3,000 invariant ticks passed headlessly and with native macOS rendering. The
native capture confirmed a docked glass shows the correct target band. All 78
original interaction checks and 33 balance checks still passed. Human retesting
of these fixes and Windows verification remain outstanding.

On 2026-11-02 the project owner confirmed the corrected flow worked well with
no observed issues. This closes that owner's reported selection regression,
not the outstanding second-creator or Windows review.

#### Equipment comparison follow-up

The owner's instruction to continue authorizes a bounded equipment experiment,
not full economy/progression. Service now offers pre-shift presets: starter
(four glasses), extra rack (six), and dishwasher (four plus a two-glass machine).
The schedule, patience, recipes, and Mode C interaction are unchanged.

Machine loading occupies hands for 1.5 seconds; an eight-second cycle then
runs while the player serves or uses the manual sink. Partial batches are
allowed. Loading/running glasses are separately accounted for; pause freezes
both phases and closing returns unfinished machine glasses dirty. The summary
includes cleaning operations initiated and approximate cleaning/loading time.
There are no purchase costs, new difficulty targets, or persistent upgrades.

Verification: 96 service scenario/UI/layout checks and 3,000 invariant ticks
passed, plus a native capture check. All 78 interaction checks and 33 balance
checks passed. The native equipment layout was visually inspected; both window
sizes passed layout bounds. Actual upgrade usefulness remains a human test,
and runtime presets do not calibrate the hypothetical economy worksheet.

On 2026-11-02 the project owner reported that equipment worked, but dishwasher
value emerged only when sufficient customers or spare glasses allowed useful
work during the automatic cycle. Record this as qualitative evidence of an
active-time versus glass-return-latency tradeoff, not proof of balanced upgrades.

Current timing explains the observation: two manual washes take six seconds
of occupied hands; a two-glass machine batch takes 1.5 seconds of occupied hands
plus eight seconds running. It saves 4.5 seconds of active work but returns that
batch after 9.5 seconds rather than returning one glass after three seconds and
the second after six. The machine is not intended as an emergency instant refill.

Do not shorten cycles or increase arrivals merely to make the machine appear
necessary. The next comparison should independently vary glass buffer and
arrival pressure, including a rack-plus-machine setup, while keeping recipes,
patience, and input consistent. Use repeatable schedules for each pressure level
and reverse setup order for the next tester. Record time with zero clean glasses,
machine waiting, hands-busy time, service outcomes, and subjective enjoyment.
That distinguishes useful parallel work from forced waiting.

Proposed acceptance: starter equipment remains comfortable at baseline demand;
a rack provides observable buffer value; a dishwasher frees useful hands-on
time at busier demand without requiring it for ordinary baseline success.
Rack-plus-machine may be complementary rather than competing upgrades, but that
is a hypothesis. Prices, unlock order, and any timing changes remain open until
this comparison is run. No gameplay values changed in response to this report.

#### Pressure/buffer comparison and future upgrade direction

The project owner endorsed future progression through increased glass capacity,
wash-speed upgrades, and eventually a busser who automatically loads and possibly
starts the dishwasher. Preserve those as future design directions, not features
implemented in the current experiment. Staff behavior, wages, unlock conditions,
manual overrides, and exact speed tiers remain undecided.

The controlled comparison now includes four presets (starter, rack, machine,
rack-plus-machine) and two repeatable schedules (baseline eight arrivals, busier
sixteen). Baseline timing is unchanged. Equipment does not change either
schedule, patience, recipes, pouring, or cleaning speed. More demand is an
explicit test selection, not a difficulty increase hidden in the default.

Completed runs export local JSON with actual setup, protocol, service outcomes,
clean-supply shortage time, potential glass-blocked time, its machine-running
subset, automatic cycle time, and hands-busy cleaning/loading time.
Potential blockage means a waiting order with neither a clean glass nor a
preparation; it does not prove that the player was inactive. Distinguish that
from merely having no clean supply while finishing a prepared drink.
The [README comparison procedure](README.md#pressure-and-buffer-comparison)
defines those measurements and the manual-export requirement.

The owner also reported buttons shifting during interaction. Fixed copy slots,
a reserved gauge slot, consistent contents height, stable button label widths,
and an always-reserved dishwasher control address state-driven layout changes.
Unavailable controls stay in place rather than collapsing the workstation.
Regression tests compare exact button rectangles through glass selection,
docking, fill changes, serving, washing, pause, and closing across all eight
equipment/pressure combinations at both candidate window sizes. Manual
retargeting and retained targets remain covered by earlier scenario tests.

Staff and faster-wash implementations remain out of scope until this equipment
comparison is reviewed. Future automated staff should remove chores without
silently overriding player actions or making the core pouring interaction moot.

Verification: 4,925 service assertions passed headlessly and with native macOS
rendering, including 3,000 invariant ticks and exact-rectangle checks over
sixteen setup/pressure/window combinations. Native capture added one successful
check and was visually inspected. All 78 interaction and 33 worksheet checks
passed after the gauge-slot change. Comparison exports were parsed and checked
for played setup, schedule, and measurement fields; test exports were removed.
Human layout retesting, busier/combined-setup feedback, and Windows remain open.

Follow-up verification: 78 lab checks passed headlessly and with native macOS
rendering; the native run also passed its viewport-capture check. Coverage
includes GUI pointer-event drag/drop, hold/release, fractional retention,
target boundaries, wrong ingredients, exports, and both candidate window sizes.
All 33 balance checks still passed. The native Mode C layout was visually
inspected. These checks do not replace the next human playtest or Windows
verification.

Validation on 2026-11-02: official Godot 4.7.2 imported the project and launched
its main scene without script errors. All 45 automated logic, integration,
layout-bound, and JSON-export checks passed headlessly and with native macOS
rendering; the native run also passed a viewport-capture check. The captured
workstation was visually inspected. Windows, packaged exports, real mouse
interaction, and human preference testing remain unverified. Test-generated
JSON and capture files were removed.

Compare:

1. Discrete assembly: choose ingredient, add measured unit, choose preparation.
2. Light tactile assembly: measured hold-to-pour, optional drag serving, and a
   short preparation action with a non-drag alternative.

Use the same workstation, two drinks, one order, and placeholder art. Exclude
economy, staff, progression, and polished menus.

Record mistakes, completion times, control confusion, and reactions after at
least ten consecutive preparations per approach. Counterbalance test order
where possible so the second approach does not always benefit from practice.

Exit gate: choose based on repeated enjoyment, clarity, and input reliability.
If neither works, revise the interaction. Do not build surrounding systems to
avoid confronting an unsuccessful test. Prototype code is disposable, not
automatically production architecture.

### Stage 5: Model workload and economy

Owners: creative lead owns balance intent; systems lead checks accounting.
Depends on Stage 4 measurements.

Tooling is prepared in advance of those measurements, not evidence that the
dependency or this stage's exit gate has passed. See the [worksheet instructions
and limitations](README.md#workload-and-economy-worksheet) and the visually
editable [assumptions resource](content/balance/worksheet.tres).
The command produces nine spreadsheet-ready scenarios: three player profiles
times baseline equipment, extra glasses, and dishwasher. It reports sustained
and rush workload, approximate glass/cycle requirements, and explicitly
conditional all-served accounting.

Initial unmeasured defaults expose an unresolved risk: learning/manual workload
is 1.134, compared with 0.866 with a dishwasher. Thus the current hypotheses do
not demonstrate comfortable recovery or two viable first purchases. This is a
design warning, not measured player performance. Calibrate preparation and
washing times, demand, glass holding, tips, and waste before using the worksheet
to approve balance. No interaction mode or production tuning is selected.

Validation on 2026-11-02: 33 worksheet checks passed, and all 45 existing lab
checks still passed. The report command generated the nine-row CSV successfully;
its header, scenario labels, monetary breakdown, and overload warnings were
inspected. These checks verify the calculations, not the underlying assumptions
or the first-slice balance gates.

Calibration, 2026-11-03: the worksheet now takes measured values from the owner's
playtests ([playtests/owner](playtests/owner/)): one mode C run of 10 drinks and one
busier service run with the rack.

| Value | Hypothesis | Measured | Source |
|---|---|---|---|
| Draft prep | 5.0 s | 5.64 s | Mode C trials 4-10 |
| Rum and cola prep | 8.0 s | 6.87 s | Mode C trials 4-10 |
| Learning slowdown | 1.5x | 1.8x | First 3 trials vs the rest |
| Manual wash | 4.0 s | 3.0 s | Service lab sink (a lab setting; click overhead not measured) |
| Glass held by guest | 12 s | 10 s | Service lab drinking time |
| Starting glasses | 6 | 4 | Service lab starter (rack adds 2) |

Cross-check: the service run served 13 of 16 at 10.7 s per serve while saturated;
the model's settled cost per order is 9.25 s, so it is about 15% optimistic
(reading and moving between stations). 3 guests were turned away because every
seat was full, and none walked out.

Findings at the worksheet's 18 guests per 4-minute shift:

- Settled player: workload 0.69, comfortable up to 20 guests. Rushes queue briefly,
  as intended.
- First-time player: workload 1.18, comfortable at about 12 guests. Mistake-heavy
  play: about 10. The dishwasher alone only reaches 0.99, so it can't be the
  recovery path.
- With 4 starting glasses, a settled player must stop to wash mid-rush; the extra
  glasses remove that. This matches the owner's "the rack was plenty useful".
- The dishwasher raises a settled player's comfortable demand from 20 to 27, so it
  pays off only once demand passes about 20 guests. This matches the owner's "only
  useful when you're busy enough". With 4 glasses, a learner using it waits on
  batches, so it works best after the rack.

Proposal for the creative lead (balance intent is hers): ramp demand by day.
Day 1 about 10 guests, day 2 about 12-14, day 3 onward 16-18, with demand above
20 reserved for players who own the dishwasher. This gives learners a recovery path
and makes the two purchases useful for different reasons: the rack for rushes, the
dishwasher for growth. Before approving: get her runs and at least two first-time
players through `tools/calibrate_balance.gd`, then check the ramp in the service lab.
Prices, tips, and purchase pacing are still unmeasured.

Day ramp presets, 2026-11-03: the service lab now offers Day 1 (10 guests), Day 2
(13), and Day 3 (17) as four-minute shifts with waves and recovery gaps. A scripted
bartender playing the real rules with measured prep times (plus 1 s per order of
movement) on starter equipment: a learner serves all of Days 1 and 2 (busy 63% and
89%) and misses 2 of 17 on Day 3; a settled player serves all of Day 3 (busy 72%).
Equipment barely changes these results at this demand, which supports keeping the
dishwasher for growth past about 20 guests. Next: owner plays the three days with
starter equipment and the rack, then the creative lead and first-time players.

- Model preparation and washing time, glasses, arrivals, patience, revenue,
  costs, tips, and purchases in a small spreadsheet or equivalent.
- Compare efficient play, learning play, mistakes, extra glasses first, and
  dishwasher first.
- Use arrival rate multiplied by average active work per customer as a rough
  workload diagnostic; separately inspect station bottlenecks and burst queues.
- Sustained demand must leave recovery capacity; temporary overload can create
  rushes.

Exit gate: learning players have a recovery path, two purchases are viable, and
normal service does not require perfect play or frequent cost waivers.

### Stage 6: Prove collaboration and authoring

Owners: systems lead establishes foundation; both perform workflow trial.
Depends on Stage 5; a minimal Godot project may exist earlier for Stage 4.

- Initialize Git locally and agree on repository access before publishing.
  (Done 2026-11-03: public repository cmgwynn/san-trago at the owner's choice;
  the creative lead's invite is still pending.)
- Pin the Godot version and ignore generated caches. (Done: `.godot-version` 4.7.2.)
- Create one reusable UI scene and a sample recipe Resource. (Done: the lab card
  scene used three times by the launcher; drink resources already existed.)
- Provide clear fields, defaults, stable IDs, examples, and validation. (Done: the
  content catalog checks IDs against file names and cross-file references.)
- Prove that a recipe can be added without editing core logic. (Done: content tests
  save a new drink and a guest who orders it, then load, validate, mix, and unlock
  its guest-book fact without code changes.)
- Produce an exported desktop build and run it outside the editor. (macOS done
  2026-11-03: the build opened all three labs from packed content, headless and
  windowed. Windows is exported but has not been run on Windows yet. CI runs every
  suite on each push and can export both builds on demand.)
- Each creator makes and merges a separate bounded change.
- Record only the setup and authoring instructions needed to reproduce this.

Exit gate: the creative lead can change a UI element and add supported content
without changing systems; the systems lead can change a rule without rewriting
content. Both can run the project and recover an earlier working revision.

### Preproduction exit gate

Both creators approve:

- The selected repeated-use interaction.
- Complete day and interruption rules.
- Screen layout and accessibility baseline.
- Workload and economy hypotheses.
- First-slice scope and exclusions.
- Successful content, Git, and export workflow.
- The production acceptance criteria below.

Any remaining uncertainty has an owner, a test, and a trigger for resolution.

## 8. Collaboration and architecture boundaries

### Responsibility split

| Area | Lead | Other creator's responsibility |
|---|---|---|
| Content, writing, art direction, balance intent | Creative | Validate system support |
| UI scenes, themes, icons, feedback | Creative | Preserve action/state contracts |
| Rules, state transitions, economy, equipment | Systems | Review gameplay consequences |
| Persistence, validation, tests, exports | Systems | Verify usable outcomes |
| Scope, playtests, major behavior changes | Both | Joint approval |

Ownership coordinates work; it does not prevent either creator from contributing.

### Intended structure

```text
scenes/       Bar, stations, customers, and reusable UI scenes
scripts/      Focused systems, interactions, UI adapters, resource types
content/      Drinks, snacks, customers, decor, upgrades, neighborhoods
assets/       Source art, audio, and fonts with usage rights recorded
themes/       Shared visual styling
tests/        Rule, state, content, and persistence checks
docs/         Approved setup and authoring guidance as needed
```

Create directories only when they contain needed work.

### System contracts

- UI requests actions; systems validate and return explicit outcomes.
- Authoritative state has one owner; presentation does not independently
  calculate money, inventory, or recipe validity.
- Resources define content; mutable session state does not live in shared
  recipe assets.
- Content uses stable IDs, not display names.
- Validate duplicate IDs, missing references, invalid quantities/prices, missing
  required presentation assets, and inaccessible recipe equipment.
- Validation reports actionable errors; invalid content must not quietly load
  as a success-shaped fallback.
- Use a small explicit phase model: prep, service, closing, results. Pause is
  an overlay that freezes simulation rather than another independent clock.
- Save data has a version; unsupported or corrupt saves surface a recoverable
  message and are not silently overwritten.
- Reuse preparation capabilities; adding a supported recipe should not need a
  new conditional branch in the engine.
- Avoid speculative frameworks, a giant global script, and one script per
  content item.

### GitHub, Live Share, and AI changes

- Git is the durable history; GitHub is the agreed shared remote.
- Live Share sessions use the host's working tree.
- Separate sessions use short-lived branches and focused pull requests.
- Avoid simultaneous edits to the same scene; split reusable UI components.
- Do not commit credentials, generated caches, or unlicensed assets.
- Review asset size before deciding whether Git LFS is needed.
- Each AI task specifies goal, owner, scope, acceptance criteria, and validation.
- Review diffs before merging; avoid concurrent AI changes to shared contracts.
- Both creators must know where state lives, how content is referenced, how to
  run validation, and how to return to a working revision.

## 9. Production sequence

Begin only after preproduction approval.

| Milestone | Outcome | Completion gate |
|---|---|---|
| 1. Reliable bartending sandbox | Chosen interaction, two drinks, serving, rejection, washing | Drink outcomes are explicit and glass accounting holds |
| 2. Complete shift | Arrivals, patience, waves, closing, results | Full shifts resolve without stranded orders or duplicated rewards |
| 3. Management and persistence | Purchases, equipment changes, decor, checkpoints | Restart preserves progress and purchases alter subsequent play |
| 4. Pacific Pour vertical slice | Cohesive presentation, tutorial, sound, balance | Meets the acceptance criteria below with external testers |
| 5. Expansion decision | Evidence-based scope for more content | Measured production cost and playtest results justify expansion |

At Milestone 5, measure the effort to finish one customer, recipe, station,
environment, and balanced shift before committing to additional neighborhoods.

Future identities remain:

- North Cork: ingredient variety and preparation accuracy.
- Gaslamp Grind: volume, staffing, and throughput.
- La Copa: presentation, premium service, and precision.

Whether moving replaces a venue, preserves it, or operates several venues is a
future scope decision. Do not build multi-venue simulation in anticipation.

## 10. Validation and first-slice acceptance

### Automated and repeatable checks

- Recipe validation: correct, missing, excess, incompatible glass, preparation.
- Glass invariant across preparation, serving, rejection, discard, abandonment,
  washing, closing, purchases, and load.
- Purchases: exact affordability, insufficient funds, repeated activation.
- Timing: pause freezes every simulation timer; closing prevents new arrivals.
- Economy: waste costs, bounded tips, explicit waivers, no negative cash.
- Persistence: checkpoint round trips, restart, duplicate-results prevention,
  corrupt and unsupported-save handling.
- Content validation for IDs, references, values, and required equipment.

Use the smallest suitable Godot-compatible test approach; choose tooling during
foundation work rather than adding a broad testing framework speculatively.

### Playtest gates

These are initial thresholds, not claims about market demand.

| Area | First-slice acceptance criterion |
|---|---|
| Learnability | At least 3 of 4 new testers serve both drinks after the introduction without verbal coaching |
| Readability | At least 3 of 4 locate orders, clean glasses, and dirty glasses without pointing |
| Reliability | Ten consecutive complete day/night cycles without blockers or corrupted state |
| Economy | At least 3 of 4 learning testers can afford a modest upgrade by the end of their third completed shift |
| Upgrade value | Testers can explain the observed workflow change from their equipment purchase |
| Authoring | Add a drink using supported mechanics without editing core systems |
| Persistence | Exported build preserves cash, purchases, settings, and completed-day progress across restart |
| Layout | Essential information and controls remain usable at both chosen window sizes |
| Accessibility | No color-only information; readable text; pause; reduced effects; alternative to precise dragging or rapid clicking |
| Continued interest | Offer an optional extra shift; record how many choose it and why; if fewer than 3 of 4 do, investigate and retest before expansion |

Use a consistent introduction, avoid coaching, record observed behavior before
opinions, and ask what felt satisfying, confusing, stressful, or repetitive.
Small samples expose usability failures; they do not prove commercial demand.

### Release preparation, later

Continue exporting throughout development. Near release, separately plan
supported operating systems, performance targets, display coverage, save
migration, accessibility review, asset/license audit, distribution testing, and
storefront requirements. Steam integration is not a substitute for these.

## 11. Risk controls and scope changes

| Risk | Early signal | Response |
|---|---|---|
| Preparation is repetitive rather than satisfying | Repeated-use tests deteriorate | Revise gestures before adding recipes |
| Pressure feels unfair | Confusion and missed warnings dominate failures | Fix readability and pacing before extending patience |
| Upgrades remove the fun | Players wait for automation instead of enjoying service | Automate chores, preserve core bartending decisions |
| Economy has a dominant choice | Nearly everyone buys the same item for necessity | Adjust alternatives and test again |
| Content production is expensive | Each item requires custom code or extensive rework | Improve supported templates; reduce content commitment |
| Visual work creates merge conflicts | Frequent shared-scene collisions | Split scenes and schedule ownership |
| AI changes diverge | Duplicate state or competing definitions appear | Stop, reconcile contracts, then resume bounded work |
| Scope expands before proof | New systems block the complete-day milestone | Defer them and restore the smallest playable loop |

For any scope addition, record the player benefit, implementation/content cost,
validation needed, and what is removed or delayed. Both creators approve changes
that affect core interaction, save behavior, content contracts, or milestones.

## 12. Initial decision log

Approval source: project owner's Stage 1 responses on 2026-11-02. Second-creator
review and the final preproduction exit gate remain outstanding. Update status,
rationale, and date as evidence and approvals arrive.

| ID | Decision | Status | Resolution gate |
|---|---|---|---|
| D01 | Godot 4.x, GDScript, Resources; no HTML/JS layer | Direction approved 2026-11-02; workflow unverified | Stage 6 |
| D02 | Fixed-view, mouse-first, single-player desktop; cozy pressure with short rushes | Approved 2026-11-02 | Validate through playtests |
| D03 | macOS and Windows; mouse/keyboard only for initial release | Approved 2026-11-02; macOS export verified 2026-11-03, Windows export built but not run | Verify exported builds on both |
| D04 | Forgiving economy without stock limits, rent, or debt | Rules approved 2026-11-02; balance unverified | Stage 5 |
| D05 | Opening checkpoint approved; detailed day/exception walkthrough drafted | Partial approval 2026-11-02 | Stage 2 review |
| D06 | Static storyboard drafted; candidate checks 1280 x 800 and 1024 x 768. Visual direction proposed: front-on, Stardew-like pixel art, bright day, San Diego (concept 01); painted golden-hour alternative with bar cat and guest book (concept 02); genre-informed layout pass 2 (speed rail, back-bar strip, serve beat) | Owner direction 2026-11-03; creative lead review pending | Stage 3 |
| D07 | C preferred after owner playtest; carry station docking and retained timed fill forward | Working choice 2026-11-02; second-creator review and tuning open | Service-context experiment and further playtests |
| D08 | Shift length, service spots, wave timing, patience, closing grace. Calibrated model (2026-11-03) proposes a day ramp: about 10, 12-14, then 16-18 guests per 4-minute shift | Open; presets Day 1-3 (10/13/17) are playable in the service lab; awaiting owner, creative lead, and first-time player runs | Stage 5, then service playtests |
| D09 | Upgrade prices and first meaningful-purchase pace | Open | Stage 5, then management playtests |
| D10 | First-slice acceptance criteria and production authorization | Proposed | Preproduction exit gate |

Owner retest, 2026-11-03: the stabilized layout held (buttons stayed put). The
rack remained clearly useful; dishwasher and rack-plus-machine under busier
pressure were not retried and remain open for a later pass. Focus moves to the
visual concept (Stage 3) before further equipment tuning.

Previous next step (still open): scope a controlled pressure/glass-buffer comparison, including
rack-plus-machine, using the equipment feedback above rather than assuming a
dishwasher speed buff is needed. Continue
while reviewing the Stage 2 walkthrough and Stage 3 screens with the second
creator. Additional B/C comparison and measured preparation times can inform
tuning and the balance worksheet. Do not begin full feature implementation
until the listed preproduction gates are satisfied.
