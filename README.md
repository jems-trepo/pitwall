# Pitwall

**Formula 1 timing at a glance.**

Pitwall is an unofficial, open-source companion app for following Formula 1
weekends. It brings session results, driver order, and the next Grand Prix into
a compact, glass-inspired interface, with a built-in view of the official F1
TV website.

![Pitwall app icon](assets/branding/pitwall_icon.png)

## Get Pitwall

Download the latest Android APK from the repository's **Releases** page and
install it on your device. Android may show a Play Protect or unknown-source
warning for an APK installed outside Google Play; review the release source
before installing.

## What it does

- View Race, Practice, and Qualifying session timing.
- See driver positions, team colors, gaps, and best valid practice or
  qualifying laps when lap data is available.
- Check the next scheduled Grand Prix and its location.
- Refresh timing manually, with automatic updates during live sessions.
- Browse the official F1 TV site inside the app from the **Watch** tab.
- Use the Pitwall-branded interface on Android and iOS.

## Live data and viewing

Timing data is retrieved from the public [OpenF1 API](https://openf1.org/), so
no API key is required. Data coverage and update timing depend on what the
upstream service publishes. Pitwall shows an unavailable or empty state rather
than inventing results when data is missing.

The Watch tab displays the official F1 TV site in an in-app web view. A
subscription may be required, and viewing options, sign-in, and playback depend
on F1 TV's regional availability and support for the device's web view. Pitwall
does not host, rebroadcast, or unlock race video.

## Project

Pitwall is developed by **JEMS**. It is an independent, unofficial project and
is not affiliated with, endorsed by, or sponsored by Formula 1, FIA, or
OpenF1. Formula 1 names and marks belong to their respective owners.

The project is intended to be open source, but a software license has not yet
been added. Until a license is published, do not assume permission to reuse,
modify, or redistribute this code or its assets.
