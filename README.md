moob: Manage Out Of Band
========================


Presentation
------------

`moob` is a command-line client for the HTTPS interfaces of out-of-band management devices.

Both the device and feature lists are quite limited as its development has mostly been driven by immediate needs at Spotify. Similarly, tests are only performed on the firmware versions we have at hand.

We currently have an inconsistent set of features for Dell iDrac6, American Megatrends, Sun and IBM devices. Patches and requests are welcome and we will do our best to make it useful to all.

Installation
------------

`moob` is known to work with both Ruby 1.8 and 1.9. To install it using `rubygems`, use:

        # gem install moob

The Debian packaging is not usable as-is, as `patron` is not distributed in any `deb`-based distribution.

Usage
-----

Use `-h` for the complete documentation.

For example, to install via PXE `foo` and `bar`, servers managed by Dell iDrac6, disregarding their current boot settings and whether they are already up:

        # moob -vm foo.lom.example.com,bar.lom.example.com -a bpxe,preset,pon
