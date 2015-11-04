moob: Manage Out Of Band [![Slack Status](http://slackin.spotify.com/badge.svg)](http://slackin.spotify.com)
========================


Presentation
------------

`moob` is a command-line client for the HTTPS interfaces of out-of-band management devices.

Both the device and feature lists are quite limited as its development has mostly been driven by immediate needs at Spotify. Similarly, tests are only performed on the firmware versions we have at hand.

We currently have an inconsistent set of features for Dell iDrac6/iDrac7/iDrac8, American Megatrends, Sun and IBM devices. Patches and requests are welcome and we will do our best to make it useful to all.

Installation
------------

`moob` is known to work with Ruby 1.9+. To install it using `rubygems`, use:

        # gem install moob

The Debian packaging is not usable as-is, as `patron` is not distributed in any `deb`-based distribution.

Usage
-----

Use `-h` for the complete documentation.

For example, to install via PXE `foo` and `bar`, servers managed by Dell iDrac6, disregarding their current boot settings and whether they are already up:

        # moob -vm foo.lom.example.com,bar.lom.example.com -a bpxe,preset,pon -t idrac6
        # moob -vm pacey.lom.example.com -a exec -t idracxml -g "racadm racreset"

Known issues
------------

* Type detection is slow and can typically take 30 seconds with some models and over slow links. Whenever the model is known, `-t` is highly recommended.
* iDrac6 works fine with R410, R510 and R610 models but failed with PowerEdge 2900 models.
