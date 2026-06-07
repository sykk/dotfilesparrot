Phase 1 — Core Theme Stack

I'd start with:

Plasma Theme

Catppuccin Mocha Global Theme

Then modify the accent colors from Catppuccin's default purple into:

Neon Green #7CFC00
Matrix Green #00FF66
Dark Emerald #00AA44

The Catppuccin Plasma theme is actively maintained for Plasma 6.

Window Decorations

Use:

Catppuccin Modern Aurora
or Klassy with custom green borders

Catppuccin Aurora decorations are available directly from KDE Store.

Icons

Instead of generic green icons:

Option A (Recommended)
Tela Circle Green
Option B
Papirus Dark
recolored folders

Many Plasma users combine Catppuccin with Papirus folder recolors for a polished look.

Phase 2 — Panel

Your current top panel is too thick.

I'd switch to:

Floating panel

Height:

32px

Opacity:

75%

Blur:

Strong

Radius:

12px

Like:

┌─────────────────────────────┐
│ workspace | clock | system │
└─────────────────────────────┘
Phase 3 — Dock

Your current dock is actually pretty close.

I would:

reduce size
add blur
increase spacing

Apps:

Konsole
Dolphin
Firefox
Discord
Steam
Spotify
System Settings

No labels.

Icons only.

Phase 4 — Konsole

This is where the magic happens.

Font

Install:

JetBrains Mono Nerd Font

or

Terminess Nerd Font
Color Scheme

Green-on-black:

Background #050505
Foreground #6BFF70
Cursor     #00FF66
Transparency

8-10%

Blur

Enabled

This alone will make the desktop feel dramatically more hacker-like.

Phase 5 — Widgets

Your wallpaper already contains fake system widgets.

Let's make real ones that match.

Install:

System Monitor Sensors

Show:

CPU
RAM
GPU
Network
Event Calendar

Transparent.

Command Output Widget

Run:

fastfetch

or

fortune

every minute.

Phase 6 — SDDM Login

This is where most rices stop.

We don't.

Make the login screen match.

Use:

Sugar Dark
Chili
Astronaut

Then recolor:

green accent
black background
Phase 7 — Evil Morty OS Branding

This is where it becomes unique.

Replace:

Hostname
sudo hostnamectl hostname citadel
Fastfetch

Custom ASCII:

██████╗██╗████████╗ █████╗ ██████╗ ███████╗██╗
██╔════╝██║╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██║
██║     ██║   ██║   ███████║██║  ██║█████╗  ██║
██║     ██║   ██║   ██╔══██║██║  ██║██╔══╝  ██║
╚██████╗██║   ██║   ██║  ██║██████╔╝███████╗███████╗

Label it:

Citadel OS
Dimension C-137
Phase 8 — Custom Theme Edit

Because you're on Arch and Plasma 6, we can go further than KDE Store.

After installing a theme we can edit:

~/.local/share/plasma/desktoptheme/

and modify:

panel glow
widget borders
transparency
hover effects
neon green outlines

Plasma themes are stored in user-accessible directories specifically for customization.

End Goal

Think:

Evil Morty's command center
Citadel mainframe
Matrix terminal
clean enough for daily use
not overloaded with RGB nonsense

A sleek black desktop with neon green highlights, floating glass panels, HUD widgets, transparent Konsole, and a custom "Citadel OS" identity.

If you want, next I can build a complete install list from store.kde.org (themes, icons, widgets, SDDM, cursor, Kvantum, Konsole, splash screen) and turn your current Plasma setup into this exact mockup.

we are talking about this mockup right

Yes, that exact mockup. Looking at it again, this is actually more achievable in Plasma 6 than you might think because most of it is just:

Transparent dark panels
Neon green accent color
Consistent icon theme
System monitor widgets
Customized Konsole
Good wallpaper
Proper spacing/layout

The biggest difference between your current desktop and this mockup is cohesion.

What I notice from your current desktop

You already have:

✅ Evil Morty wallpaper
✅ Dark translucent top panel
✅ Green accent color
✅ Floating dock
✅ Modern icon style

But:

❌ Icons are blue/cyan instead of green
❌ Dock style doesn't match wallpaper
❌ No HUD widgets
❌ Konsole isn't themed as part of the desktop
❌ Panel is visually disconnected from the wallpaper
❌ Green isn't used consistently

What I'd install first
Global Theme

I'd skip Catppuccin.

For this particular rice I would use:

Sweet KDE

or

Utterly-Round-Dark

as a base and recolor everything green.

These have much better transparency and blur effects than most Plasma themes.

Icons
Tela Circle Green

This is probably the closest icon pack to the mockup.

Your current icons are too colorful.

We want:

Black
Dark Gray
Neon Green

Nothing else.

Cursor
Bibata Modern Ice

Then recolor green.

Or create:

Citadel Cursor

using Bibata as the base.

Dock

For the mockup I'd actually use:

Latte Dock Fork

instead of Plasma Panel.

Configure:

Blur: High
Opacity: 70%
Radius: 16px

Then make it float.

Konsole

This is huge.

The mockup's terminal is basically:

Background: #020202
Foreground: #7CFF6B
Cursor: #00FF66
Opacity: 90%

Then:

JetBrainsMono Nerd Font

Size 12

No transparency on text.

Widgets

The right side is what sells the whole theme.

Install:

Plasma System Monitor

Create:

System Overview
CPU
RAM
Network
Disk

with green graph colors.

Then place them exactly like the mockup.

Top Bar

Your current panel is very close.

I would:

Left
Kickoff
Activities
Workspaces
Center
Clock
Date
Right
Discord
Network
Volume
Bluetooth
Power

Remove everything else.

