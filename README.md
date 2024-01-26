# docker-ripper

[![Github Sponsorship](https://img.shields.io/badge/support-me-red.svg)](https://github.com/users/rix1337/sponsorship)

This container will detect optical disks by their type and rip them automatically.

# Output

Disc Type | Output | Tools used
---|---|---
CD | MP3 FLAC ISO | abcde (lame and flac), ddrescue
Data-Disk | ISO | ddrescue
DVD | MKV and ISO | MakeMKV, ddrescue
BluRay | MKV and ISO | MakeMKV, ddrescue

### Prerequistites

#### (1) Create the required directories, for example, in /home/yourusername. Do _not_ use sudo mkdir to achieve this.

```
mkdir config rips
```

#### (2) Find out the name(s) of the optical drive

```
lsscsi -g
```

In this example, /dev/sr0 and /dev/sg0 are the two files that refer to a single optical drive. These names will be
needed for the docker run command.  
![lsscsi -g](https://raw.githubusercontent.com/rix1337/docker-ripper/main/.github/screenshots/lsscsi.png)

Screenshot of Docker run command with the example provided  
![docker run](https://raw.githubusercontent.com/rix1337/docker-ripper/main/.github/screenshots/dockerrun.png)

## Docker run

In the command below, the paths refer to the output from your lsscsi-g command, along with your config and rips
directories. If you created /home/yourusername/config and /home/yourusername/rips then those are your paths.

```
docker run -d \
  --name="Ripper" \
  -v /path/to/config/:/config:rw \
  -v /path/to/rips/:/out:rw \
  -p port:9090 \
  --device=/dev/sr0:/dev/sr0 \
  --device=/dev/sg0:/dev/sg0 \
  rix1337/docker-ripper:manual-latest
  ```

Some systems are not able to pass through optical drives without this flag
`--privileged`

#### Configuring the web UI for logs

Add these optional parameters when running the container
````
  -e /ripper-ui=OPTIONAL_WEB_UI_PATH_PREFIX \ 
  -e myusername=OPTIONAL_WEB_UI_USERNAME \ 
  -e strongpassword=OPTIONAL_WEB_UI_PASSWORD \
````

`OPTIONAL_WEB_UI_USERNAME ` and `OPTIONAL_WEB_UI_PASSWORD ` both need to be set to enable http basic auth for the web UI.
`OPTIONAL_WEB_UI_PATH_PREFIX ` can be used to set a path prefix (e.g. `/ripper-ui`). This is useful when you are running multiple services at one domain.

### Please note

**To properly detect optical disk types in a docker environment this script relies on makemkvcon output.**

MakeMKV is free while in Beta, but requires a valid license key. Ripper tries to fetch the latest free beta key on
launch. Without a purchased license key Ripper may stop running at any time.

#### If you have purchased a license key to MakeMKV/Ripper:

1) after starting the container, go into the config directory you created, edit the file
   called `enter-your-key-then-rename-to.settings.conf`, and add your key between the
   quotes `app_Key = "`**[ENTER KEY HERE]**`"` then save and rename the file to settings.conf

![makemkv license](https://raw.githubusercontent.com/rix1337/docker-ripper/main/.github/screenshots/makemkvkey.png)

2) Remove the remaining file `enter-your-key-then-rename-to.settings.conf`
   ![sudo rm enter your key](https://raw.githubusercontent.com/rix1337/docker-ripper/main/.github/screenshots/sudormenteryourkey.png)

3) At this point your config directory should look like this:  
   ![config directory](https://raw.githubusercontent.com/rix1337/docker-ripper/main/.github/screenshots/configdirectory.png)

## Docker compose

Check the device mount points and optional settings before you run the container!

`docker-compose up -d`

### Environment Variables

- `EJECTENABLED`: Optional - If set to `true`, the disc is ejected after ripping is completed. Default is `true`.
- `JUSTMAKEISO`: Optional - If `true`, only an ISO of the disc is created. Default is `false`.
- `STORAGE_CD`: Optional - The path for storing ripped CD content. Default is `/out/Ripper/CD`.
- `STORAGE_DATA`: Optional - The path for storing data disc ISOs. Default is `/out/Ripper/DATA`.
- `STORAGE_DVD`: Optional - The path for storing ripped DVD content. Default is `/out/Ripper/DVD`.
- `STORAGE_BD`: Optional - The path for storing ripped BluRay content. Default is `/out/Ripper/BluRay`.
- `DRIVE`: Optional - The device file for the optical drive (e.g., `/dev/sr0`). Default is `/dev/sr0`.
- `BAD_THRESHOLD`: Optional - The number of allowed consecutive bad read attempts before failing. Default is `5`.
- `DEBUG`: Optional - Enables verbose logging when set to `true`. Default is `false`.
- `DEBUGTOWEB`: Optional - If `true`, debug logs are published to the web UI. Default is `false`.
- `SEPARATERAWFINISH`: Optional - When `true`, separates raw and final rips into different directories. Default is `false`.
- `ALSOMAKEISO`: Optional - If `true`, creates an additional ISO image alongside the normal rip operation. Default is `false`.
- `TIMESTAMPPREFIX`: Optional - If `true`, prefixes output folders with a timestamp for organization. Default is `false`.
- `MINIMUMLENGTH`: Optional - The minimum length of a title in seconds to be considered valid.(Applies to DVD and BluRAY) Default is `600`.

### Building and Running with Docker Compose

First clone the repository:

```git clone https://github.com/rix1337/docker-ripper.git```

You can build and run docker-ripper using Docker Compose, which simplifies the process of deploying and managing containers

- To build the image:
  
  ```docker-compose build```
This will use the latest/Dockerfile to build an image tagged as `rix1337/docker-ripper:latest`.

To start the container:

```docker-compose up -d``` or ```docker-compose up``
This command with the `-d` flag will start the container in detached mode, meaning it will run in the background. Without the `-d` flag, the container will run in the foreground and log to the console. You can stop the container with `docker-compose stop` or `docker-compose down`. The latter will also remove the container. 

Logs can be viewed with `docker-compose logs` or `docker-compose logs -f` to follow the logs in real time.

If you prefer to build the Docker image manually without Docker Compose, you can use the docker build command:

To build the "latest" image using Docker:

```docker build -f latest/Dockerfile -t rix1337/docker-ripper:latest .```

This command performs the same operation as the docker-compose build but requires manual input of build context and parameters.

Remember to periodically pull the latest changes from the git repository to keep your Dockerfile up to date and rebuild the image if any updates have been made.



# FAQ

### MakeMKV needs an update!

_You will need to use a purchased license key - or have to wait until an updated image is available. Issues regarding this will be closed unanswered._

_You will find the PPA-based build under the `latest`/`ppa-latest` tags on docker hub. These should be the most stable way to run ripper. A manual build of makemkv can be found unter the `manual-latest` and versioned tags. For users without a License key it is recommended to use the `manual-latest` image, as it is updated much faster to newly released makemkv versions - that are required when running with the free beta key._

### Do you offer support?

_Yes, but only for my [sponsors](https://github.com/sponsors/rix1337). Not a sponsor - no support. Want to help yourself? Fork this repo and try fixing it yourself. I will happily review your pull request. For more information see [LICENSE.md](https://github.com/rix1337/docker-ripper/blob/main/LICENSE.md)_

### There is an error regarding 'ccextractor'

Add the following line to settings.conf

```
app_ccextractor = "/usr/local/bin/ccextractor" 
```

### How do I set ripper to do something else?

_Ripper will place a bash-file ([ripper.sh](https://github.com/rix1337/docker-ripper/blob/main/root/ripper/ripper.sh))
automatically at /config that is responsible for detecting and ripping disks. You are completely free to modify it on
your local docker host. No modifications to this main image are required for minor edits to that file._

_Additionally, you have the option of creating medium-specific override scripts in that same directory location:_

Medium | Script Name | Purpose
--- | --- | ---
BluRay | `BLURAYrip.sh` | Overrides BluRay ripping commands in `ripper.sh` with script operation
DVD | `DVDrip.sh` | Overrides DVD ripping commands in `ripper.sh` with script operation
Audio CD | `CDrip.sh` | Overrides audio CD ripping commands in `ripper.sh` with script operation
Data-Disk | `DATArip.sh` | Overrides data disk ripping commands in `ripper.sh` with script operation

_Note that these optional scripts must be of the specified name, have executable permissions set, and be in the same
directory as `ripper.sh` to be executed._

### How do I rip from multiple drives simultaneously?

**This is unsupported!**

Users have however been able to achieve this by running multiple containers of this image, passing through each drive to only one instance of the container, when disabling privileged mode.

### How do I customize the audio ripping output?

_You need to edit /config/abcde.conf_

### I want another output format that requires another piece of software!

_You need to fork this image and build it yourself on docker hub. A good starting point is
the [Dockerfile](https://github.com/rix1337/docker-ripper/blob/main/latest/Dockerfile#L29) that includes setup instructions
for the used ripping software. If your solution works better than the current one, I will happily review your pull
request._

### Am I allowed to use this in a commercial setting?

_Yes, see [LICENSE.md](https://github.com/rix1337/docker-ripper/blob/main/LICENSE.md)._
**If this project is helpful to your organization please sponsor me
on [Github Sponsors](https://github.com/sponsors/rix1337)!**

### The docker keeps locking up and/or crashing and/or stops reading from the drive

_Have you checked the docker host's udev rule for persistent storage for a common flaw?_

```
sudo cp /usr/lib/udev/rules.d/60-persistent-storage.rules /etc/udev/rules.d/60-persistent-storage.rules
sudo vim /etc/udev/rules.d/60-persistent-storage.rules
```

_In the file you should be looking for this line:_
```
# probe filesystem metadata of optical drives which have a media inserted
KERNEL=="sr*", ENV{DISK_EJECT_REQUEST}!="?*", ENV{ID_CDROM_MEDIA_TRACK_COUNT_DATA}=="?*", ENV{ID_CDROM_MEDIA_SESSION_LAST_OFFSET}=="?*", \
  IMPORT{builtin}="blkid --offset=$env{ID_CDROM_MEDIA_SESSION_LAST_OFFSET}"
# single-session CDs do not have ID_CDROM_MEDIA_SESSION_LAST_OFFSET
KERNEL=="sr*", ENV{DISK_EJECT_REQUEST}!="?*", ENV{ID_CDROM_MEDIA_TRACK_COUNT_DATA}=="?*", ENV{ID_CDROM_MEDIA_SESSION_LAST_OFFSET}=="", \
  IMPORT{builtin}="blkid --noraid"
```

_Those IMPORT lines cause issues so we need to replace them with a line that tells udev to end additional rules for SR* devices:_
```
# probe filesystem metadata of optical drives which have a media inserted
KERNEL=="sr*", ENV{DISK_EJECT_REQUEST}!="?*", ENV{ID_CDROM_MEDIA_TRACK_COUNT_DATA}=="?*", ENV{ID_CDROM_MEDIA_SESSION_LAST_OFFSET}=="?*", \
  GOTO="persistent_storage_end"
##  IMPORT{builtin}="blkid --offset=$env{ID_CDROM_MEDIA_SESSION_LAST_OFFSET}"
# single-session CDs do not have ID_CDROM_MEDIA_SESSION_LAST_OFFSET
KERNEL=="sr*", ENV{DISK_EJECT_REQUEST}!="?*", ENV{ID_CDROM_MEDIA_TRACK_COUNT_DATA}=="?*", ENV{ID_CDROM_MEDIA_SESSION_LAST_OFFSET}=="", \
  GOTO="persistent_storage_end"
##  IMPORT{builtin}="blkid --noraid"
```

_You can comment these lines out or delete them all together, then replace them with the GOTO lines. You may then either reboot OR reload the rules. If you're using Unraid, you'll need to edit the original udev rule and reload._
```
root@linuxbox# udevadm control --reload-rules && udevadm trigger
```


# Credits

- [Idea based on Discbox by kingeek](http://kinggeek.co.uk/projects/item/61-discbox-linux-bash-script-to-automatically-rip-cds-dvds-and-blue-ray-with-multiple-optical-drives-and-no-user-intervention)

  Kingeek uses proper tools (like udev) to detect disk types. This is impossible in docker right now. Hence, most of the
  work is done by MakeMKV (see above).

- [MakeMKV Setup for manual-build by tianon](https://github.com/tianon/dockerfiles/blob/master/makemkv/Dockerfile)

- [MakeMKV key/version fetcher by metalight](http://blog.metalight.dk/2016/03/makemkv-wrapper-with-auto-updater.html)
