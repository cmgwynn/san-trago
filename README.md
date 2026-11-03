# San Trago / Bartending Lab

A disposable Godot experiment for a two-person cozy coastal bartending game.
This is not the vertical slice: it deliberately excludes customers, patience,
money, washing, upgrades, and game-progress saving.
Those exclusions describe the original interaction lab. A separate service
experiment now adds guests, patience, real glass circulation, and manual washing;
Neither scene implements money, purchased progression, or persistent game
progress. The service scene now offers equipment presets for comparison.

## Open and run

1. Install the standard (non-.NET) **Godot 4.7.2** editor for macOS or Windows
   from the [official release](https://github.com/godotengine/godot/releases/tag/4.7.2-stable).
   Both creators should use that version.
2. In Godot, choose **Import**, select [project.godot](project.godot), and open it.
3. Press **F5** to open the lab launcher and pick a lab, or open a lab scene and
   press **F6**. In any lab, **Ctrl+L** (or **Cmd+L** on Mac) returns to the launcher.
4. In the interaction lab, choose experiment A, B, or C and start a ten-drink run.
   The station experiment C is selected by default.

The project uses the compatibility renderer. No external fonts, art, packages,
account credentials, or network access are needed to play.

## Service rhythm experiment

Open [service_lab.tscn](scenes/service_lab.tscn) in Godot and press **F6** to run
that scene. **F5 still opens the original interaction lab**, intentionally.
Alternatively run:

```sh
godot --path . res://scenes/service_lab.tscn
```

- Start the short shift. Eight scheduled arrivals use three counter spots.
- Before starting, choose **Starter** (four glasses and sink), **Extra rack**
  (six glasses and sink), or **Dishwasher** (four glasses, sink, and batch machine).
  **Rack + machine** combines six glasses and the same two-glass dishwasher.
  Setup cannot change mid-shift. Arrivals, patience, and recipes stay identical.
- Click a waiting guest to choose the order and serving recipient. A `>` marks
  selection, with a persistent pressed highlight. Drinking guests are not
  selectable orders. Changing guests never deletes the prepared drink.
- After serving, the next waiting guest is selected automatically if there is
  no preparation to preserve. A clean glass prepared before the next arrival
  picks up that arrival's recipe automatically.
- Once a glass has a recipe reference, a departure or reused customer spot
  cannot silently change its targets. The gauge keeps the preparation recipe
  and asks you to choose a new recipient. Explicitly selecting another waiting
  guest updates targets without deleting liquid; check for incompatible contents.
- Target bands appear when a glass is docked and a recipe is known. Before
  that, instructions explain the missing step instead of showing an empty bar.
  With no waiting guests and no recipe reference, there is no invented target.
- Use Mode C's glass docking and retained-fill pouring, then serve.
- Four actual glasses circulate through preparation, guests, dirty supply, and
  the sink. Served guests keep their glass for ten seconds before returning it.
- Wash one dirty glass in a three-second action. This occupies your hands:
  no simultaneous pouring or serving, but patience and arrivals continue.
  Any drink on the counter remains intact.
- With the dishwasher preset, **Load up to 2 / Start batch** takes up to two
  dirty glasses. Loading occupies your hands for 1.5 seconds, then the eight-second
  cycle runs automatically while you pour or use the sink. A one-glass batch is
  allowed; there is no automatic load or instant clean-glass refill.
- Pause freezes both loading and the automatic cycle. Closing returns unfinished
  machine glasses dirty, without deleting or duplicating them.
- Patience is initially sixty seconds. A full counter causes scheduled arrivals
  to move on rather than forming an invisible queue.
- Arrivals include quiet gaps and two closer pairs. New arrivals stop at two
  minutes, with up to twenty-five seconds to finish existing guests.
- Pause, application focus loss, and discard confirmation freeze the whole
  service simulation. A discard turns the preparation glass dirty.
- Closing returns held glasses and discards unfinished preparation. A summary
  distinguishes served guests, patience walkouts, missed arrivals, and orders
  left at closing. It also reports sink washes/batches initiated and approximate
  hands-busy cleaning/loading time (not time spent pouring). Restart resets
  everything. Game progress is not saved. Completed comparisons can now be
  exported before restarting.

All counts and times are explicit test hypotheses, not tuned release balance.
The [service model](scripts/systems/service_shift.gd) owns customer/glass state;
the [service controller](scripts/ui/service_lab.gd) reuses the original lab's
pour controls through an inherited scene. This is experiment reuse, not a
commitment to inheritance as the final game's architecture.

Playtest questions: does docking still feel natural while tracking guests?
Is the target readable at the same time as patience? Does washing create a
satisfying change of pace or merely interrupt the fun? Can you identify where
every glass went? Does the default shift feel cozy, empty, or too demanding?
Feedback is more valuable than optimizing the served count.

For equipment comparison, try the same shift with all three presets and reverse
the order for another tester. Note whether the rack helps you postpone washing,
whether the machine's batch delay creates useful planning, and whether either
feels necessary instead of optional. Do not equate higher served counts with
greater enjoyment. At this gentle pacing, upgrades may have little impact; that
is a valid finding, not a reason to secretly increase difficulty.
These runtime assumptions differ from the uncalibrated worksheet defaults.
Neither tool yet demonstrates balanced prices or a justified purchase order.

### Pressure and buffer comparison

Choose **Baseline / 8 guests** or **Busier / 16 guests** before starting.
Baseline retains the previously tested schedule. Busier uses a fixed schedule
with clustered arrivals and quiet gaps over the same two-minute opening.
Patience, drinking time, recipes, pouring tolerance, sink speed, and machine
timings do not change between setups or pressure levels. More arrivals can
move on when the three service spots are full; there is no hidden queue.

Compare all four equipment choices at one pressure level before interpreting
differences. You do not need to complete eight shifts in one sitting. Reverse
setup order for another tester to reduce practice effects.

Diagnostics use simulation time and exclude pause/focus loss and confirmation
dialogs. Durations are sampled in up-to-0.05-second slices:

- **No clean supply:** clean count is zero, whether or not work is blocked.
- **Glass-blocked:** at least one waiting order, no clean glass, and no glass
  already being prepared. This is potential resource blockage, not measured
  player inactivity; a sink wash may already be underway.
- **Machine-blocked subset:** glass-blocked time while the automatic cycle is
  running, excluding loading. Do not add it again to total blocked time.
- **Machine running:** automatic cycle time, whether or not the player did
  useful work during it. That needs observation and subjective feedback.
- **Hands busy:** manual washing/loading only, not pouring or automatic cycles.

After closing, **Export service comparison (JSON)** writes the actual played
setup, schedule, timings, outcomes, errors, discards, and diagnostic totals to
`service_comparisons/` in Godot's user-data folder. The full path is displayed.
Exports contain no player identifiers and are not uploaded. Export before
restarting or closing if you want to keep a result; there is no automatic save
or overwrite-protection prompt for this experimental service summary.

Ask whether rack-plus-machine creates useful breathing room rather than simply
waiting for cleaning. Starter equipment should remain comfortable at baseline;
busier is a diagnostic challenge, not the new default difficulty.

### Day ramp presets

**Day 1 / 10 guests**, **Day 2 / 13 guests**, and **Day 3 / 17 guests** are the
proposed first days from the calibrated worksheet: four-minute shifts with small
waves and recovery gaps. Play them in order with starter equipment, then again
with the rack, and export each run. Day 1 should feel relaxed, Day 2 steady, and
Day 3 busy but fair. Then collect the runs:

```bash
godot --headless --path . --script tools/calibrate_balance.gd -- --collect --player=owner
```

`tools/day_ramp_report.gd` plays every preset with a scripted bartender
([service_bot.gd](scripts/systems/service_bot.gd)) at settled, learning, and
mistake-heavy speeds. It uses the real service rules and the measured prep times
plus 1 s per order for moving around. It is a sanity check, not a player: on
starter equipment it serves all of Days 1 and 2 at learning speed (busy 63% and
89% of the time), and all of Day 3 when settled (busy 72%), while a learner misses
2 of 17. Tests keep those properties.

```bash
godot --headless --path . --script tools/day_ramp_report.gd
```
Glass-capacity tiers, faster washing/equipment, and a busser who loads or starts
the machine are future progression directions, not implemented presets.

### Stable interaction layout

The service workstation reserves space for the gauge even before a glass is
docked, and for changing recipe/status copy. The gauge itself only appears when
its reference is known. Button hitboxes remain stationary when labels, contents,
selection, washing, pause, or closing status change. The dishwasher control stays
in place as unavailable on setups without it. Start and Pause retain explicit
usable widths alongside both setup selectors.

Tests compare exact button rectangles across all four setups and both pressure
levels at 1280 x 800 and 1024 x 768. This verifies state changes at a fixed window
size, not that deliberately resizing a window leaves coordinates unchanged.

## What to try

- **A:** ingredient buttons add one measured unit per press.
- **B:** hold an ingredient button for 0.65 seconds per unit; release or move off
  the button to stop. The progress bar shows the next measured unit. This
  original reference mode still resets its incomplete unit when released.
- **C:** select a glass, then drag the glass button onto an ingredient station,
  or tap the station to dock without dragging. Dropping/docking never starts
  pouring automatically. Hold the docked station to pour, then release to stop.
  Holding a different station first docks there; a second press begins pouring.
  The glass button names its drag affordance; the docked station says GLASS HERE.
- C stores fractional amounts immediately. Releasing, switching stations, or
  pausing never erases liquid already poured. Resuming requires a fresh hold.
- In C, stop inside the marked target band: required amount plus or minus
  **0.25 units**. Both boundaries count. There is no automatic cutoff or snap to
  the target. An incorrect ingredient is never allowed by that tolerance.
- The target gauge and numeric label identify underfill, acceptable fill, and
  overpour without relying on color. Overpours require discarding; underfills
  can be topped up. Partial progress is reset only by serving or discarding.
- The **+1** buttons remain available in A/B. They are hidden in C, which tests
  timed pouring; tapping a station replaces precise dragging, not timed holding.
- Select a glass, follow the visible recipe, then serve.
- Incorrect serving preserves the glass and explains the problem.
- Discarding a nonempty drink asks for confirmation.
- Escape pauses. Losing application focus also pauses and cancels pouring.
- Successful service immediately returns the reusable test glass. This is a
  deliberate experiment shortcut, not the planned glass/washing simulation.

Ten orders now use a fixed varied sequence, still five beer and five rum/cola,
identically in every mode. This removes strict back-and-forth repetition without
changing the content. More recipes remain a later decision.
Complete and export each mode separately. The app protects completed unexported
results from a new run, but closing the app still loses unexported results.
There is no persistent game save or mid-run recovery in this experiment.

## Compare fairly

1. Practice both drinks before the measured comparison; practice is not a result.
2. Compare B and C to evaluate retained fill and station interaction. Have one
   tester try B then C and another C then B. A remains a click-only reference.
3. Keep recipes and workspace unchanged between modes.
4. Export both completed runs and record tester/order separately without private
   identifying information.
5. Note enjoyment, confusion, physical effort, repetition, and preference.
6. Look at time, mistakes, discards, and hold-input usage together. Faster alone
   does not mean more enjoyable.

Times include reading and corrections, but exclude pause, application focus loss,
and discard-confirmation time. The export records measured-button versus hold
usage so accessible alternatives do not get mistaken for hold-only results.
This comparison tests input feel, not rush pacing or economic balance. C changes
both station interaction and tolerance, so preference for C does not isolate
which change helped. Capture that distinction in feedback.

Exports now use schema version 2 with experiment ID, order sequence, recipe IDs,
served quantities, target tolerance, and drag/tap counts. Do not mix earlier
alternating-sequence exports with these as if the protocols were identical.
Fractional held quantities in C are measured in units, not number of presses.

**Export completed run** writes JSON under Godot's local user-data directory in
`interaction_runs/` and displays the full path. In the editor, use **Project >
Open User Data Folder** to find it. Results are not uploaded or tracked by Git.
An export failure is displayed explicitly and does not unlock overwriting results.

## Layout lab and guest book

Open [layout_lab.tscn](scenes/layout_lab.tscn) and press **F6**, or run:

```sh
godot --path . res://scenes/layout_lab.tscn
```

This is a gray-box of the [visual concept 02](docs/visual-concept-02.html) service
screen: the same zones at 1600 x 900, letterboxed to any window. It has no art,
pouring, or shift timer. It tests the zones and the guest-book loop, which uses
the real guest book system.

- Click a ticket (or press **Left**/**Right**) to put that guest in the arch. The
  next guest waits on a stool at the end of the bar.
- Press **1**-**4** or click a speed-rail slot to pick a pour source (draft, rum,
  cola, nuts). The tutorial tag beside the glass follows your pick.
- **Serve perfect** (or **Space**) and **Serve sloppy** in the top bar record a visit
  and the guest's usual drink.
- **Chat** asks the guest in the arch about their topic. **Churro** pets the cat.
- When you learn a fact, a red badge appears on the guest book and a toast names
  the fact. Open the book from the counter or with **Tab**. It opens at the guest with news, and new
  facts are marked NEW until you turn the page or close the book (**Tab** or **Esc**).

Tickets, recipe blocks, and the speech card come from guest content: each guest's
usual drink and first small-talk topic.

## Editing responsibilities

- Creative/content: [drink resources](content/drinks/) and the
  [workstation scene](scenes/bartending_lab.tscn). Open a drink in Godot's Inspector
  to edit its name, description, and quantities. IDs must remain unique.
- Creative/content: [guest resources](content/guests/). Each guest has a usual drink
  (a drink ID; leave it empty for guests who don't order, like Churro), small-talk
  topics (an ID plus the line the guest says), and facts. A fact unlocks after a number
  of visits, perfect serves, or serves of a drink ID, or after a small-talk topic
  (topic facts need a hint, and the topic must be one the guest brings up). It can
  also require another fact first. Facts unlock in list order. The guest book tests
  validate every guest file.
- Systems: [drink validation](scripts/systems/drink_workbench.gd),
  [metered pouring](scripts/systems/metered_pour.gd),
  [guest book](scripts/systems/guest_book.gd), and
  [lab controller](scripts/ui/bartending_lab.gd).
- Shared design: [preproduction plan](PREPRODUCTION-PLAN.md) and
  [static screen storyboard](docs/screen-storyboard.html), and
  [visual concept 01](docs/visual-concept.html) (pixel-art service screen and palette) and
  [visual concept 02](docs/visual-concept-02.html) (painted golden-hour alternative).

New drinks and guests need no code changes: save a new `.tres` in
[content/drinks](content/drinks/) or [content/guests](content/guests/) (duplicate an
existing one in Godot's FileSystem dock), give it an ID that matches its file name,
and run the tests. The [content catalog](scripts/content/content_catalog.gd) finds
it, and the guest book, layout lab, and validation pick it up. The interaction and
service labs keep their fixed two-drink lists on purpose, so their timed runs stay
comparable. The launcher's [lab card](scenes/ui/lab_card.tscn) is the shared,
restylable UI piece: edit it once and every card changes.

Ingredient rows are generated by the disposable lab controller; the surrounding
layout is visually editable in the scene. The fixed three-ingredient schema is
intentional for this experiment, not the final extensible ingredient catalog.
Descriptions must match quantities when changing recipes.

## Workload and economy worksheet

The separate [balance model](scripts/systems/balance_model.gd) compares efficient,
learning, and mistake-heavy service against baseline equipment, extra glasses,
and a dishwasher. It does not change or select either interaction experiment.

Open [worksheet.tres](content/balance/worksheet.tres) in the Godot Inspector to
edit the assumptions. Currency fields use integer cents. Prep times, the learning
multiplier, wash time, glasses, and drinking time are **calibrated from playtests**
(see below). Prices, tips, arrivals, rush shape, waste, and dishwasher figures are
still unmeasured hypotheses.

### Calibrating from playtests

Play the interaction lab in mode C and the service lab, then collect your runs
and recalibrate:

```sh
godot --headless --path . --script tools/calibrate_balance.gd -- --collect --player=yourname
godot --headless --path . --script tools/calibrate_balance.gd -- --write
```

`--collect` copies your saved runs into [playtests/](playtests/)`yourname/` so they
are shared through Git. Without `--write`, the tool only prints what would change.
It measures [only what the runs show](scripts/systems/playtest_calibration.gd):
settled prep time per drink (mode C trials after the first three), the learning
multiplier (first three trials compared with the rest), wash time, and the lab's
glass count and drinking time. More players make it better; a test fails if the
worksheet falls out of sync with `playtests/`.

Generate a spreadsheet-ready report:

```sh
godot --headless --path . --script tools/balance_report.gd
```

The command prints the comparison and writes `balance-report.csv` in the same
Godot user-data folder described above. Re-running replaces this report; copy it
elsewhere with its assumptions if you want to compare tuning revisions.

Interpretation:

- Workload ratio = arrival rate times estimated active work per order. A value
  at or above 1 leaves no recovery capacity.
- Rush workload uses the rush arrival rate. Backlog estimates start with an
  empty queue and do not simulate walkouts, service spots, or glass shortages.
- Extra glasses increase the buffer, not the player's work speed. "Rush glasses
  to skip washing" is how many clean glasses it takes to serve a whole rush
  before washing; fewer than that triggers "Must stop to wash mid-rush".
- "Comfortable arrivals" is how many guests per shift keep workload at the
  `comfortable_workload` target (0.8 by default). Use it to set demand per day.
- Dishwasher workload includes active loading; its separate utilization ratio
  checks batch-cycle throughput. Full-batch waiting and glass circulation are
  rough steady-state estimates, not a scheduling simulation.
- Waste fraction means additional discarded drink-equivalents per served drink,
  not the chance of failing every attempt. It increases preparation, washing,
  and ingredient consumption.
- All-served profit assumes every arrival buys one drink and the configured tip.
  It is an optimistic accounting scenario, **not an earnings prediction**, especially
  when overload warnings appear. It excludes snacks, operating costs, waived
  charges, customer patience, and supply purchasing.
- Upgrade affordability assumes starting from zero savings and repeating that
  all-served profit. It does not prove the purchase is worthwhile or that the
  learning-player economy gate passes. `-1` means no positive profit.
- Waste is included once in ingredient costs; never subtract it again.

Calibrated findings (2026-11-03, one player): at 18 guests per 4-minute shift a
settled player is comfortable (workload 0.69, comfortable up to 20), but a first-time
player is overloaded (1.18, comfortable at about 12). The dishwasher alone doesn't
fix that (0.99). The recovery path has to come from demand: start days light and
ramp up. See the [plan's Stage 5 findings](PREPRODUCTION-PLAN.md#stage-5-model-workload-and-economy).
Do not select a faster input mode solely to rescue an overloaded service design.

## Validate

Run every suite at once (point `GODOT` at your Godot executable):

```sh
GODOT=/Applications/Godot.app/Contents/MacOS/Godot tools/run_all_tests.sh
```

It imports the project, runs each suite in `tests/`, prints one line per suite, and
exits non-zero if any check fails. GitHub runs the same script on every push and
pull request (see [CI](.github/workflows/ci.yml)); a red X on a pull request means
don't merge yet. To run one suite:
`godot --headless --path . --script tests/content_tests.gd`.

### Desktop builds

Builds need the Godot 4.7.2 export templates (Editor > Manage Export Templates >
Download). Then export with **Project > Export**, or:

```sh
godot --headless --path . --export-release "macOS" "exports/macos/San Trago.zip"
godot --headless --path . --export-release "Windows" "exports/windows/San Trago.exe"
```

`exports/` is not committed. To get builds without installing templates, open the
repository's **Actions** tab, choose **CI**, then **Run workflow**; the macOS and
Windows builds appear as downloads on that run. Check a build outside the editor
with `<app or exe> -- --smoke`: it opens every lab, prints `SMOKE OK ...`, and exits.
The macOS build is not notarized, so the first launch needs right-click > **Open**.
Windows may show a SmartScreen warning (**More info > Run anyway**).

Tests cover drink correctness, recovery, content validation, measured-pour
thresholds, completed runs, result protection, pause/focus behavior, and layout
bounds. C checks include actual Godot GUI pointer-driven dragging/holding/release,
per-ingredient partial retention, target boundaries, wrong ingredients,
overpours, and fractional result exports. Content checks cover folder discovery,
cross-file references, ID and file-name mismatches, and adding a drink and guest
with no code changes. Launcher checks cover every lab card and returning with
Ctrl/Cmd+L. Calibration checks cover hand-calculated measurements from synthetic
runs, ignoring non-station modes and non-run files, and the shipped worksheet staying
in sync with `playtests/`. The macOS export has been smoke-tested outside the editor; the Windows
export is built but has not been run on Windows. Native visual feel and human
preference still need separate checks.
Balance tests independently cover hand-calculated totals, workload and machine
capacity, waste accounting, CSV row shape, zero demand, and invalid inputs.
Service checks cover allocation, rejection, dirty returns, washing, pause,
discard confirmation, closing, restart, and scene bounds, plus glass conservation
over 3,000 simulation ticks. The service scene has no export or save feature.
Guest book checks cover every unlock type, thresholds, chained facts unlocking in one
event, generated hints, read state, save round trips (including removed and newly
added facts), and content validation. Layout lab checks cover zone and button
overlap, keeping the guest's face clear, a centered work area, a single guest-book
entry point, a 15 px minimum text size, speed-rail hotkeys, guest cycling, toast
wrapping, letterboxing at four window sizes, and the serve-to-book loop.
Selection regressions additionally cover post-service automatic selection,
preselecting a clean glass before an arrival, retained recipe targets after
departures/spot reuse, explicit retargeting, washing/focus retention, and a
held pour interrupted by closing. Large service frames are processed in small
slices so pouring cannot run for an entire frame past closing.

## Work together

The project is on GitHub at [cmgwynn/san-trago](https://github.com/cmgwynn/san-trago).
It is public, so never commit passwords, keys, or anything you wouldn't post online.
Both of you should use Godot 4.7.2 (see `.godot-version`).

1. Get the latest `main`: `git switch main && git pull`.
2. Make a branch for one bounded change: `git switch -c content/maya-facts`. Use
   `content/`, `ui/`, or `art/` for creative work and `systems/` for logic.
3. Commit small steps. Run the test suites in [Validate](#validate) before pushing.
4. Push and open a pull request (`gh pr create --fill`); the other person reviews and merges.
5. Avoid both editing the same `.tscn` scene at once. Scenes merge badly, so say
   who has which scene, or pair on it in Live Share from the host's working tree.

Godot's `.godot/` cache and `exports/` are ignored; `.uid` files are committed
alongside their scripts. Collaboration is set up, but the Stage 6 trial (each of
you merging a separate change, plus an exported build) has not been done yet.
