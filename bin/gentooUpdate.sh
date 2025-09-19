#!/bin/bash

emerge --sync && \
emerge --oneshot -uv sys-apps/portage && \
emerge -uv --keep-going y --exclude www-client/chromium --exclude www-client/firefox @world && \
emerge -uDNv --keep-going y --exclude www-client/chromium --exclude www-client/firefox @world && \
emerge -uv @preserved-rebuild && \
emerge --depclean
emerge -v @preserved-rebuild
