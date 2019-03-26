# L'BEL Card

[![Build Status](https://travis-ci.org/protocubo/lbelcard.svg?branch=master)](https://travis-ci.org/protocubo/lbelcard)

This repository contains all code used to run the L'BEL Card hotsite, a web
application to request pre-paid credit cards through AcessoCard, for over a
year.

The codebase contains real world examples of:

 - a web application built on a Haxe, Neko, Tora and SQLite stack
 - accessing and handling the returns of some AcessoCard APIs
 - a framework for asynchronous/long tasks within Tora
 - effective live reloading and module caching in Tora
 - a health check API

This system was used to power `lbelcard.com.br`, continuously, from 12 December
2017 until 27 February 2019.

On 28 February 2019 the website was replaced with an informational-only [static
page][hotsite] and new credit cards can no longer be requested.  By then 1590
requests had been successfully processed.

The [changelog](CHANGES.md) shows how the system evolved over time, and is a
interesting read.

[hotsite]: https://lbelcard.com.br

## Building and running locally

Dependencies:

 - programming language: [Haxe v4][haxe]
 - runtime: [Neko][neko]
 - library management: [Haxe Module Manager (hmm)][hmm]
 - application server: [Tora][tora]
 - database: [SQLite][sqlite]

[haxe]: https://haxe.org
[neko]: https://nekovm.org
[hmm]: https://github.com/andywhite37/hmm
[tora]: https://github.com/HaxeFoundation/tora
[sqlite]: https://sqlite.org/index.html

```bash
# Install libraries and build
hmm install
haxe dev.hxml

# And start a development server
#
# Notes:
#  - asks for the password to AcessoCard's API
#  - uses placeholders for other credentials (adjust if you have proper access)
#  - starts nginx automatically (nginx is required)
#  - expects `tora` to be in the path (instructions in the script)
docs/dev-server
```

The production application is meant to run on Linux.  Some tweaks might be
necessary to run the development server on Mac OS or Windows, particularly to
its corresponding script.

## Copyright and license

Web application to request pre-paid credit cards through AcessoCard.  
Copyright © 2017–2019  Protocubo

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Affero General Public License for more
details.

You should have received a copy of the GNU Affero General Public License along
with this program.  If not, see <https://www.gnu.org/licenses/>.
