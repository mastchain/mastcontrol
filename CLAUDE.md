# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repo contains a single Bash script (`mastcontrol.sh`) — a control script for **MastRadar**, a fork of [AIS-catcher](https://github.com/jvde-github/AIS-catcher). It installs, configures, and manages a systemd service (`mastradar.service`) that ships AIS (ship tracking) data to `api.mastchain.io`.

The script self-installs to `/usr/local/bin/mastcontrol` and must be run as root (it auto-re-runs with `sudo` if not).
