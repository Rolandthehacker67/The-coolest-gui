# Nocturne UI

> *Liquid glass, obsidian refraction. 14,000 lines of one file. Zero features. Zero assets. Zero regrets.*

**Nocturne UI** is a dark “liquid glass” interface for Roblox — the translucent, refractive, iOS-27-meets-macOS look — implemented as **a single Luau file** with no dependencies, no assets, and deliberately **no real functionality**. Every button is a placeholder. Every switch toggles itself and nothing else. It exists to be beautiful, to be given away, and to be stripped down into the skeleton of something useful.

![Luau](https://img.shields.io/badge/Luau-single%20file-blue) ![Lines](https://img.shields.io/badge/lines-14k%2B-brightgreen) ![Assets](https://img.shields.io/badge/assets-used-0-red) ![License](https://img.shields.io/badge/license-MIT-green)

---

## Install

1. Open Roblox Studio.
2. `StarterPlayer → StarterPlayerScripts → Insert Object → LocalScript`.
3. Paste the entire contents of [`NocturneUI.lua`](NocturneUI.lua).
4. Press play. The boot curtain lifts on a working desktop.

That’s it. There is no step 5. There are no images to upload, no decal IDs, no font packs, no module folders, no peer dependencies. If your game’s asset permissions are “none whatsoever,” this still works.

> **Why does the volume slider work then?** Settings is the one app with a job: it actually edits the kit’s own config. It is the exception that proves the rule — the rule being that Nocturne does not touch your game.

## What you get

### The glass itself
- **Spring physics everywhere** — windows don’t tween, they *settle*: overshoot, squash, wobble. Custom critically-damped spring solver, single `RenderStepped` pump.
- **Cursor-tracked specular sheen** on every surface, drifting **caustic light strips**, rim light with gradient falloff, procedural film grain on capable hardware.
- **Scene depth**: opening a palette, lock screen or mission control pushes background glass away with real `BlurEffect` + dim + contrast, spring-eased.
- **Wobble on click** — every glass surface takes a spring impulse when you poke it.

### A whole desktop
- **Window manager** — drag, resize from corners, snap to screen halves/quarters (drag into edges), minimise to the dock with genie-style spring, mission-control overview (`Ctrl+.`), cascade, tile.
- **Dock** with magnification on hover, running indicators, bouncing launch animation.
- **Menu bar** with live clock, working dropdown menus, battery *lies*.
- **Command palette** (`Ctrl+K`) with fuzzy search across apps, themes, accents and toggles.
- **Notification centre**, toasts, do-not-disturb, a history that forgets anything older than 60 entries.
- **Spotlight-style right-click context menus** on the desktop, dock and window chrome.
- **Lock screen** — big clock, recent-notif minis, spring-panel unlock. Click anywhere to get back in.
- **Live wallpaper** — gradient bed, three parallax orbs that follow the cursor, procedural starfield, and it shuffles from the palette.

### Ten placeholder apps (all cosmetic, some interactive-with-itself)
| App | The bit that fools people |
|---|---|
| **Settings** | Actually re-paints the entire kit live: 9 themes, 12 accents, glass thickness, rim light, caustics, wobble, grain, motion & a11y toggles, reset, config JSON dump |
| **Home** | Real clock card, session gauge, quick-action chips that snap windows around |
| **Sound Lab** | Media player with a visualiser driven by the same fbm noise as the caustics; play/pause really pauses *the animation* |
| **Messages** | Bubbles that pop in on springs, fake replies after a typing indicator, canvas autoscroll |
| **Terminal** | Typewriter boot log + a command interpreter (`help`, `theme`, `accent`, `blur`, `wobble`, `open`, `count`, `echo`, `sudo`) with ↑/↓ history |
| **Tasks** | Checkboxes that wobble row 2; the list never gets shorter, it just changes mood |
| **Files** | A fake tree you can drill into; one folder is named `features` and is empty (on purpose) |
| **Weather** | Coin-flip forecast using the procedural sun/cloud/rain glyphs |
| **Stats** | Four live bar-graph cards pumped at 10 Hz — fps, frame time, surfaces, scheduler tasks |
| **About + Cheats** | Spinning logo, MIT license card, and a keycap cheat sheet where every key is clickable |

### The small obsessions
- ~60 procedurally-drawn icons (`IconKit`) — every glyph is frames+corners+gradients, including traffic lights, keycaps and battery.
- Synthesised UI SFX: the kit generates its own PCM `Sound` buffers at runtime (taps, slides, cheats, boot chime) — no audio asset IDs anywhere, and a 12-voice budget.
- FPS watchdog: sustained sub-40 fps downgrades caustics/grain/particles automatically; the Stats window shows you the crime.
- Reduce-motion and high-contrast modes; `Esc` closes the top-most thing like a gentleman.
- Konami code (`↑↑↓↓←→←→BA`) flips the kit into **LIQUID MODE** — everything wobbles harder and the caustics turn up. Also secret: `RIG-HEAD` contrast, `QUIET` mute, `WOBBLE` chaos. They do nothing useful, as intended.
- Studio-only preference autosave (`save`/`reset` in the palette), pcall-guarded so live servers never notice.

## Scripting it from your own code (optional)

The file self-boots, but it also leaves a single table behind. If you convert it into a ModuleScript (one click in Studio: right-click → *Convert To Module*) and require it:

```lua
local Nocturne = require(path.to.NocturneUI)
Nocturne.Bootstrap.run()          -- no auto-boot in module mode; you drive

Nocturne.notify("Hello from your game", { title = "Friend" })
Nocturne.open("settings")
Nocturne.setTheme("aurora")
Nocturne.setAccent("coral")
Nocturne.glassPreset("airy")

-- Or make your own placeholder widgets:
local panel = Nocturne.Glass.panel(Nocturne.App.layers.window, {
    size = UDim2.fromScale(0.3, 0.25),
    roundness = 26,
    tint = 0.14,
})
Nocturne.Widgets.button(panel.content, {
    label = "Continue",
    variant = "primary",
    onClicked = function() print("now *your* button can do something") end,
})

Nocturne.selfTest()                -- pcall smoke-tests every subsystem
Nocturne.destroy()                 -- wipes all glass; for hot-reload heroes
```

Key hotkeys: `Ctrl+K` palette · `Ctrl+,` settings · `Ctrl+E` mission control · `Ctrl+M` minimise focused window · `Ctrl+J` dock · `Ctrl+N` notification centre · `Ctrl+Shift+L` lock screen · `Ctrl+Shift+P` capture flash · `Ctrl+Shift+F` show/hide the whole kit · `Ctrl+Shift+/` fps chip. Every one is remappable in `Config.input.keybinds`. The cheats app lists them all, and clicking a keycap *does* the thing.

## House rules

- **One file.** No build step, no bundler, no “core” + “extras”. Paste it, ship it.
- **No features.** The kit never reads or writes your game state. What it *looks* like it’s doing, it isn’t doing.
- **No assets.** If a future version ever needs a decal ID, you have my written permission to be furious.
- **MIT.** Keep the ASCII-art header, and say hi if you ship something beautiful with it.

## FAQ

**Why?** Because a GUI kit should be judged on its glass, and because “give it to somebody else” should never mean “explain your asset permissions to them.”

**Is it performant?** One scheduler drives every animation; throttled pumps, pooled particles, dirty-flag painting, device-capability detection. On low-spec clients the watchdog sheds effects within a second.

**Can I sell / fork / rebrand it?** Yes (MIT). Attribution is courtesy, not law — except for the header’s name, which legally you may remove; morally, leave it, it took ages to kern.

**Where are the features?** Ask the empty `features` folder in Files.

---

*“Nothing is connected to anything, by design.”* — the welcome window, and also the philosophy.
