#!/bin/bash

emerge --sync
emerge --oneshot -uv sys-apps/portage
emerge -uv @world
# emerge -uDNv  @world
emerge -uv @preserved-rebuild
emerge --depclean
