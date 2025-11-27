# Changelogs

## [v0.0.2] Model spinning fix + Transparent UIs | 2025/11/26

Fixed model spinning when the primary part isn't centered.

UI instances are no longer visible when coin is collected.

## [v0.0.1] User interface + Small fixes | 2025/11/10

Added a user interface:
- Displays current score / target score.
- Nino Nakano as the default icon.

Made the collect coin sound play from `workspace` (2D sound) instead of from the coin part (3D sound).

... among other small changes.

## [v0.0.0] Coin & PurpleCoins module + Sample script | 2025/11/09

First commit!

Ported & refactored the code from *Cien Purple Coins en Windy Isla* (currently a private game).
- Combined into a framework under a single `ReplicatedStorage` module.

`Coin` submodule for making collectible coins, either server or client-sided.

`PurpleCoins` module for grouping and handling `Coins`.

Sample script under `ServerScriptService` to demonstrate creating a simple purple coins challenge.
