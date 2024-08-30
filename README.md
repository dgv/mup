# μploader - Micro Uploader
[![reference Zig](https://img.shields.io/badge/zig%20-0.13.0-orange)](https://github.com/dgv/mup/blob/main/build.zig.zon)
[![reference Zig](https://img.shields.io/badge/deps%20-1-orange)](https://github.com/dgv/mup/blob/main/build.zig.zon)
[![build](https://github.com/dgv/mup/actions/workflows/build.yml/badge.svg)](https://github.com/dgv/mup/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

![img](https://private-user-images.githubusercontent.com/5204494/361256991-268d853f-9b69-4fa1-853e-e645818c3f6d.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MjU5MjkwODMsIm5iZiI6MTcyNTkyODc4MywicGF0aCI6Ii81MjA0NDk0LzM2MTI1Njk5MS0yNjhkODUzZi05YjY5LTRmYTEtODUzZS1lNjQ1ODE4YzNmNmQucG5nP1gtQW16LUFsZ29yaXRobT1BV1M0LUhNQUMtU0hBMjU2JlgtQW16LUNyZWRlbnRpYWw9QUtJQVZDT0RZTFNBNTNQUUs0WkElMkYyMDI0MDkxMCUyRnVzLWVhc3QtMSUyRnMzJTJGYXdzNF9yZXF1ZXN0JlgtQW16LURhdGU9MjAyNDA5MTBUMDAzOTQzWiZYLUFtei1FeHBpcmVzPTMwMCZYLUFtei1TaWduYXR1cmU9MzlhMjM5M2Y3MWI5YzkwMGU4OTJjZTUwMzI2YmRlZWNiYWU1NTJhOTk5YTA0NWZjYzQ0Yjk1OTY3NjBkNjZiNCZYLUFtei1TaWduZWRIZWFkZXJzPWhvc3QmYWN0b3JfaWQ9MCZrZXlfaWQ9MCZyZXBvX2lkPTAifQ.Oq70focCMEsKVs_-Vv6V0Cp_O9QjUvsCa8K1jl4x4m4)

A simple file uploader that can be used to easily move and share files across the local network between devices with a web browser.

It only uses [httpz](https://github.com/go-chi/chi) as dependency and the releases provide a statically linked binary.

**Motivation.**
_Sometimes I want to move files between my pc and a device I do not own that has an old browser version (that generally means expired https certificates, oh and without any cables). When I try to search for a tool like this I always find random outdated projects that aren't easy to setup. So I made this tool that can be easily installed on all linux systems._<br>[@aziis98](https://github.com/aziis98)

## Installation

### Static Binary from Release

Run the following command to install the latest version to `~/.local/bin/mup`

```bash
curl -sSL https://raw.githubusercontent.com/dgv/mup/main/install | sh
```

Then you can run `mup` from anywhere in your terminal, the default upload directory is `Uploads` so this can even be run directly from the home folder (only the files inside `Uploads` are served to the client).

### Git

```bash
$ git clone https://github.com/dgv/mup
$ cd mup

# Run the server
$ zig build run -- .

# Build the binary
$ zig build
```
