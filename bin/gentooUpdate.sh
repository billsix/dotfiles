#!/bin/bash

pushd .
cd /var/db/repos/gentoo/
emerge --sync
git add -A .
git commit -m 'updated'
emerge --oneshot -uv sys-apps/portage
emerge -uDNv  @world
emerge -uUD --backtrack=100 @world
emerge --depclean
#emerge -uv @world
emerge -uv @preserved-rebuild
popd 



