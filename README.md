# sp

Fetch the latest spot prices for precious metals, from the command line.

## Description

*sp* fetches the latest precious metal spot prices by way of an undocumented API
provided by a popular retail website. The API only updates every 2 minutes, so
when using *sp* to automate requests, it is inadvisable to request any faster
than this limit. Unfortunately, the details preceding means that *sp* is
inherently unstable, and liable to break at any moment in time. Use caution as
appropriate.

*sp* consists of a single *POSIX compliant* shell script, and is written in a
portable manner - save for the small list of dependencies:

- [curl](https://github.com/curl/curl)
- [jq](https://github.com/stedolan/jq)
- sed

Despite the size of the project, and its narrow purpose, *sp* comes with a
comprehensive man page, as all good tools should.

## Purpose

To provide a way of fetching precious metal spot prices from the command line, so
the data may be stored/used for further processing.

## Example Output

The output of *sp* is purposefully designed to be as easy as possible to pipe to
other unix tools - i.e., `awk`, `jq`, `cut`, etc. - and tries to follow the
*Unix Philosophy*.

Without any arguments, *sp* should output something similar to:

```
01/06/17 18:58 gold 983.04 gbp toz
01/06/17 18:58 silver 13.388 gbp toz
01/06/17 18:58 platinum 723.29 gbp toz
01/06/17 18:58 palladium 641.45 gbp toz
```

## To Do

- [ ] Store ajax token to file for saving bandwidth when making repeat requests.

## Copyright

*sp* is released into the public domain.
