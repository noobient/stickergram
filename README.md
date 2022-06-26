# About

Stickergram is a collection of Bash scripts for converting existing stickers or images to Telegram format. Then you can upload those stickers to Telegram via the [Stickers Bot](https://telegram.me/stickers). These scripts aren't too professional, user-friendly, or robust, it's just a quick-n-dirty solution to fulfill my needs, but eventually I decided I should release them to the public, because it could be useful to some of you.

The scripts should be fairly fast, because I've tried to use parallelism wherever it makes sense.

# Prerequisites

## OS

### Linux

Stickergram is developed on and for **Ubuntu 22.04**. Please note that for certain image conversions, **Ubuntu 20.04 LTS is not compatible** due to some libraries being too old to work with certain image formats.

If you're on something older than 22.04, or if you use another distro, you can try to use Stickergram anyway, it might work for your use case. If not, I recommend using Docker:

```
docker run -it ubuntu:22.04
```

### Windows

If you're on Windows, either use Docker, or use **WSL2**, which is perfectly compatible. In fact, **I develop Stickergram on WSL2**. If you're on an older release of Ubuntu and don't want to migrate your environment to a new WSL2 instance, you can do an in-place upgrade to 22.04 from within WSL2:

```
sudo sed -i.orig 's/focal/jammy/g' /etc/apt/sources.list
sudo sed -i.orig 's/focal/jammy/g' /etc/apt/sources.list.d/*
sudo apt update
sudo apt dist-upgrade
```

## Packages

Since Stickergram operates on images, it needs a few related utilities:

```
sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt install apngasm apngdis imagemagick ffmpeg golang jq webp
go get github.com/ericchiang/pup
```

WebP images need some manual compilation, so for the time being, you'll also need these:

```
sudo apt install git gcc make autoconf automake libtool libgif-dev libpng-dev
```

# Installation

```
git clone https://github.com/noobient/stickergram.git
```

# Usage

## Structure

All you need to do is save your sticker files (PNG or JPG) under:

```
dist/<sticker_pack_name>/orig
```

The rest will be created automatically by Stickergram, and the resulting tree will look something like this:

```
📦stickergram
 ┗ 📂dist
    ┗ 📂<sticker_pack_name>
       ┣ 📂conv
       ┣ 📂fuzz
       ┣ 📂icon
       ┣ 📂orig
       ┣ 📂resi
       ┣ 📂temp
       ┗ 📜icon.conf
```

Here's what these do:

| Folder | Description |
|---|---|
| `dist` | Main sticker dir, short for "distribution" |
| `<sticker_pack_name>` | The name of your sticker pack, use any alphanumeric string you like, e.g.: `Octocorn` |
| `conv` | Short for "conversion", used to convert JPGs to PNG, APNGs to WebM, etc. |
| `fuzz` | Used for "fuzz" static images |
| `icon` | Directory for storing the sticker icon |
| `orig` | Directory holding the original source images |
| `resi` | Short for "resized", up/downscaled images go here |
| `temp` | Intermediate temporary files go here |
| `icon.conf` | This file stores the preferred sticker file in the pack for generating the icon |

## Static stickers

These should be transparent PNGs, usually downloaded from some other chat app's sticker store. This is really easy, all the files need is some resizing:

```
./resize.sh <sticker_pack_name>
```

The resulting stickers will be saved under `dist/<sticker_pack_name>/resi`.

## Animated stickers

These should be transparent animated PNG or WebP files, usually downloaded from some other chat app's sticker store. These need to be resized first, then converted to WebM.

```
./resize.sh <sticker_pack_name>
./convert.sh <sticker_pack_name>
```

The resulting stickers will be saved under `dist/<sticker_pack_name>/conv`.

## Static images

These are random PNGs or JPGs that you found on the internet, but might be usable for making stickers. Think of drawings with few distinct colors and vivid borders - like a sticker. Since these aren't specifically made to be stickers, they usually lack transparency, and thus there's no exact, precise solution to turn them into stickers. The edges need to be detected, and transparency needs to be added with some kind of "fuzzing". The best level of "fuzziness" needs to be picked by manually checking them, so Stickergram generates a sticker for each level of fuzz on a scale of 1 to 20.

```
./insta.sh <sticker_pack_name>
```

The resulting stickers will be saved under `dist/<sticker_pack_name>/resi`.

## Pack Icons

Telegram icons have a corresponding icon that's shown in the chat client in the sticker list. These icons have different specs, so you need to generate an icon for each sticker pack. It's really easy:

```
./icon.sh <sticker_pack_name> <file_to_use_as_icon_without_file_extension>
```

The resulting icon will be saved under `dist/<sticker_pack_name>/icon`.

The icon file preference will be saved in `iconf.conf`, so on consecutive runs you can omit the icon file:

```
./icon.sh <sticker_pack_name>
```

# Uploading

These are well covered in the [Telegram Stickers](https://core.telegram.org/stickers) article, but here's a crash course. I recommend you to add just one sticker to a new pack, set up all the details for the pack, save it, then add the remaining stickers to the pack afterwards.

Start a new chat with @Stickers, then:

- `/newpack`
- sticker pack name
- send first sticker PNG
- send corresponding emoji(s)
- `/publish`
- send icon PNG
- sticker pack ID

If you're adding animated stickers, substitute `/newpack` with `/newvideo`. Add additional stickers with `/addsticker`.
