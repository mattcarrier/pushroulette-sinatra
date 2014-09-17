pushroulette-sinatra
====================

RESTFul PushRoulette

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
# store some songs
curl --data '' http://localhost:4567/store/clips?num=5

# for development run in pushroulette-sinatra directory
thin start
```

## Install Service

```bash
# store some songs
curl --data '' http://localhost:4567/store/clips?num=5

# install init.d script and start service
sudo cp pushroulette-sinatra/admin/initd/pushroulette-sinatra /etc/init.d/
sudo service pushroulette-sinatra start
```
