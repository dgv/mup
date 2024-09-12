# μploader - Micro Uploader
[![reference Zig](https://img.shields.io/badge/zig%20-0.13.0-orange)](https://github.com/dgv/mup/blob/main/build.zig.zon)
[![reference Zig](https://img.shields.io/badge/deps%20-2-orange)](https://github.com/dgv/mup/blob/main/build.zig.zon)
[![build](https://github.com/dgv/mup/actions/workflows/build.yml/badge.svg)](https://github.com/dgv/mup/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

![mup](https://github.com/dgv/mup/blob/main/mup.png)

Rewritten of [mup](https://github.com/aziis98), a simple file uploader that can be used to easily move and share files across the local network between devices with a web browser.

It only uses [httpz](https://github.com/karlseguin/http.zig) and [zig-clap](https://github.com/Hejsil/zig-clap) as dependencies and provide a statically linked binary.

### Motivation
[@aziis98](https://github.com/aziis98):
_Sometimes I want to move files between my pc and a device I do not own that has an old browser version (that generally means expired https certificates, oh and without any cables). When I try to search for a tool like this I always find random outdated projects that aren't easy to setup. So I made this tool that can be easily installed on all linux systems._

[@dgv](https://github.com/dgv):
_size comparison_
```bash
# go binary striping symbol and debug info..tinygo?
$ go build -ldflags "-s -w"; du mup
16704	mup
...
# zig binary -65x
$ zig build --release=small; du zig-out/bin/mup
256	zig-out/bin/mup
```


### Git

```bash
$ git clone https://github.com/dgv/mup
$ cd mup

# Run the server
$ zig build run

# Build the binary
$ zig build
```

### Dockerfile

I provide this just to easily deploy on a local server. I **do not recomend to expose this publicly** on the web as there is no auth or password and there is no upload limit to the number of files and all files in the `Uploads/` folder are public by default for now.

```bash shell
$ docker build -t mup .
$ docker run -p 5000:5000 -v $PWD/uploads:/uploads mup
```


## Usage

```bash
$ mup --help
-h, --help
        Display this help and exit.

-s, --size <usize>
        Maximum upload size in MB.

-p, --port <u16>
        Port to run the server on.

-h, --host <str>
        Host to run the server on.

-d, --dir <str>
        Upload directory to serve files.
```
