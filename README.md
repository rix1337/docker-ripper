# docker-ripper
This container will detect optical disks by their type and rip them automatically.


[![Join the chat at https://gitter.im/docker-ripper/Lobby](https://badges.gitter.im/docker-ripper/Lobby.svg)](https://gitter.im/docker-ripper/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# Output
Disc Type | Output | Tools used
---|---|---
CD | MP3 and FLAC | Ripit (lame and flac)
Data-Disk | Uncompressed .ISO | ddrescue
DVD | MKV | MakeMKV
BluRay | MKV | MakeMKV

**To properly detect optical disk types in a docker environment this script relies on makemkvcon output.**

MakeMKV is free while in Beta, but requires a valid license key. Ripper tries to fetch the latest free beta key on launch. Without a purchased license key Ripper may stop running at any time.

To add your purchased license key to MakeMKV/Ripper add it to the `enter-your-key-then-rename-to.settings.conf` at `app_Key = "`**[ENTER KEY HERE]**`"` and rename the file to settings.conf.

# Credits
- [Idea based on Discbox by kingeek](http://kinggeek.co.uk/projects/item/61-discbox-linux-bash-script-to-automatically-rip-cds-dvds-and-blue-ray-with-multiple-optical-drives-and-no-user-intervention)

  Kingeek uses proper tools (like udev) to detect disk types. This is impossible in docker right now. Hence, most of the work is done by MakeMKV (see above).

- [MakeMKV Setup by tobbenb](https://github.com/tobbenb/docker-containers)

- [MakeMKV key/version fetcher by metalight](http://blog.metalight.dk/2016/03/makemkv-wrapper-with-auto-updater.html)

```
docker run -d \
  --name="Ripper" \
  -v /path/to/config/:/config:rw \
  -v /path/to/rips/:/out:rw \
  --device=/dev/sr0:/dev/sr0 \
  rix1337/docker-ripper
  ```
