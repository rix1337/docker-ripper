# docker-ripper
This container will detect optical disks by their type and rip them automatically.

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

# FAQ

*How do I set ripper do do something else?*

_Ripper will place a bash-file ([ripper.sh](https://github.com/rix1337/docker-ripper/blob/master/root/ripper/ripper.sh)) automatically at /config that is responsible for detecting and ripping disks. You are completely free to modify it on your local docker host. No modifications to this main image are required for minor edits to that file._

*I want another output format that requires another piece of software!*

_You need to fork this image and build it yourself on docker hub. A good starting point is the [Dockerfile](https://github.com/rix1337/docker-ripper/blob/master/Dockerfile#L30) that includes setup instructions for the used ripping software.

*MakeMKV needs an update!*

_Make sure you have pulled the latest image. The image should be updated automatically as soon as MakeMKV is updated. This has not worked reliably in the past. Just [open a new issue](https://github.com/rix1337/docker-ripper/issues/new) and I will trigger the build.

*Am I allowed to use this in a commercial setting?*

_Yes - I suggest a donation that reflects the amount of saved work hours in your organization. Just send me a PM on [gitter](https://gitter.im/rix1337)._

*Do you offer support?

_If you feel the need, open an issue on this github repo. I am not responsible if anything breaks. For more information see [LICENSE.md](https://github.com/rix1337/docker-ripper/LICENSE.md)

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
