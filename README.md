pushroulette-sinatra
====================

RESTful PushRoulette

## Installation

    git clone https://github.com/Astonish-Results/pushroulette-sinatra

## Dependencies

Install bundler if not already installed:
```bash
gem install bundler
```

Run Bundle install to install dependencies
```bash
bundle install
```

Linux (using aptitude):
```bash
apt-get install espeak
```

Requires [libav](https://libav.org/) for encoding and decoding all non-wav files (which work natively)

## Getting libav set up

Mac (using [homebrew](http://brew.sh)):

```bash
brew install libav --with-libvorbis --with-sdl --with-theora
```

Linux (using aptitude):

```bash
apt-get install ffmpeg libavcodec-extra-53
```

## Development

```bash
# for development run in pushroulette-sinatra directory
thin start

# store some songs
curl --data '' http://localhost:4567/initialize
```

## Install Service

```bash
# install init.d script and start service
sudo cp pushroulette-sinatra/admin/initd/pushroulette-sinatra /etc/init.d/
sudo service pushroulette-sinatra start

# store some songs
curl --data '' http://localhost:4567/initialize
```
