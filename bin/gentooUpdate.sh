#!/bin/bash

emerge --sync && \
emerge --oneshot -uv sys-apps/portage && \
emerge -uv --keep-going y @world && \
emerge -uDNv --keep-going y @world && \
emerge -uv @preserved-rebuild && \
emerge --depclean
