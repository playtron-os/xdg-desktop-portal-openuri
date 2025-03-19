# xdg-desktop-portal-openuri

A lightweight D-Bus service implementing the `org.freedesktop.portal.OpenURI` interface to open URLs via `xdg-open`. Designed for minimal Fedora-based systems (e.g., PlaytronOS) to support Proton applications like `steam-runtime-urlopen`.

## Features
- Provides a simple `OpenURI` portal frontend for D-Bus.
- Opens URLs using `xdg-open` with configurable `DISPLAY` environment.
- MIT-licensed for flexible use in commercial and open-source projects.

## Installation

### From COPR
Available on Fedora COPR:
```bash
sudo dnf copr enable playtron/gaming
sudo dnf install xdg-desktop-portal-openuri