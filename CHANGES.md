# Changelog

## Current merge window: v1.0.0

To be released December 20th, 2017.

Fully functional server, open to the general public.

This release includes many fixes and improvements over the initial v1.0.0-rc1,
including adaptive rate limiting since there will be no throttling of
invitations.

 - Fix tabindices for /novo, /novo/dados and /novo/confirma


## Third release candidate: v1.0.0-rc3

December 20th, 2017.

 - Log the human-attributed system version during init
 - Prevent accidental double request confirmation (closes #4)
 - Add failsafe against going over the card limit per user (related to #4)
 - _Rename L'BELcard to L'BEL Card_
 - _Refuse to authorize users if the queue is already too long_
 - _Add text to the status page for context_
 - Fix missing HTML5 DOCTYPE declaration
 - Fix footer links
 - _Add phone numbers to the footer_
 - _Make styling and content changes requested by BELCORP's marketing department_


## Second release candidate: v1.0.0-rc2

December 19th, 2017.

 - Fix typo in the main form
 - Add server version to the User-Agent string
 - Don't re-enqueue AcessoUserOrDataError
 - Log queue size on dequeue
 - Reduce forced stalls to prevent rate limits
 - Reduce the sleep time in the handler loop
 - Add failsafe to prevent accidental card fabrication during local builds
 - Trace the user number when starting a new card request
 - Fix storage of remote call timings (see #3)
 - Fix warning asserts on queued vs. state
 - Do not discard a module after a dispatch error
 - Add empty robots.txt
 - Fix datestring conversion into timestamps and SerializedDate
 - Count Failed states other than user error towards the request limit
 - _Change favicon to L'_


## First release candidate: v1.0.0-rc1

December 12th, 2017.

Fully functional server.

 - Fix #1: call update() after setting the last (successful) state

