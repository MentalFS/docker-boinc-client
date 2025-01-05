# docker-boinc-client

A Docker image for the [BOINC client](https://github.com/BOINC/boinc).

This image does not include the GUI client and should be used via [boinccmd](https://manpages.debian.org/stable/boinc-client/boinccmd.1.en.html) or remotely.

When the GUI RPC Port is routed, it is also possible to control the client remotely with [BOINC Manager](https://boinc.berkeley.edu/wiki/BOINC_Manager) or [boinctui](https://packages.debian.org/stable/boinctui) (only recommended for `localhost`).

## Tags
| Tag                 |                                                            |
|---------------------|------------------------------------------------------------|
| `release`, `latest` | Uses the official BOINC APT release repository             |
| `alpha`             | Uses the official BOINC APT pre-release / alpha repository |

## Volumes

| Path                    |                             |
|-------------------------|------------------------------
| `/var/lib/boinc-client` | Data and settings for BOINC |

## Ports

| Port  |              |
|-------|---------------
| 31416 | GUI RPC port |

## Supported settings

| Environment Variable            | Default     |                                                                                       |
|---------------------------------|-------------|---------------------------------------------------------------------------------------|
| `GUI_RPC_AUTH`                  | *empty*     | The password for GUI RPC, empty means no password                                     |
| `DEVICE_NAME`                   | *empty*     | The device name will default to the docker hostname (usually random) if not set       |
| `HOST_VENUE`                    | *empty*     | Host venue type: `none`, `home`, `school` or `work`                                   |
| `MAX_NCPUS_PCT`                 | `100`       | Percentage of CPU cores to use, *empty* uses website preferences                      |
| `CPU_USAGE_LIMIT`               | `100`       | Load percentage to use, *empty* uses website preferences                              |
| `SUSPEND_CPU_USAGE`             | `0.0`       | Suspend when non-BOINC CPU usage is above (only useful with `--pid=host`              |
| `RAM_MAX_USED_PCT`              | *empty*     | Percentage of RAM to use at max, *empty* uses website preferences                     |
| `CPU_SCHEDULING_PERIOD_MINUTES` | *empty*     | Switch between tasks/projects every X minutes                                         |
| `DISK_INTERVAL`                 | *empty*     | Interval in seconds to save state to disk, *empty* uses website preferences           |
| `WORK_BUF_MIN_DAYS`             | *empty*     | Store enough tasks to keep the computer busy for this long (in Days, decimal number)  |
| `WORK_BUF_ADDITIONAL_DAYS`      | *empty*     | Store additional tasks above the minimum level (in Days, decimal number)              |
| `MILKYWAY_NCPUS`                | * empty*    | Number of CPU cores per task to use in [MilkyWay@home](https://milkyway.cs.rpi.edu/)  |

## Download

```
docker pull ghcr.io/mentalfs/boinc-client
```

## Example

Starting:
```bash
docker run --name boinc \
  -e GUI_RPC_AUTH="correct horse battery staple" \
  -e DEVICE_NAME="${HOSTNAME}-docker" \
  -e MAX_NCPUS_PCT=50 \
  -p 127.0.0.1:31416:31416 \
  -v boinc-data:/var/lib/boinc-client \
  --gpus all \
  -d ghcr.io/mentalfs/boinc-client
```

Send command:
```bash
docker exec boinc boinccmd --get_project_status
```

More command info:
```bash
docker exec boinc boinccmd --help
```

Start boinctui:
```bash
docker exec -it boinc boinctui
```


## Notes

* `global_prefs_override.xml` will be overwritten to use environment variables.
* The option `allow_remote_gui_rpc` will be set to `1`, allowing all hosts to connect to the GUI RPC.
* GPUs are usable with `--gpus`, `--privileged` (not recommended) or `--device /dev/dri:/dev/dri` depending on GPU model.
* Docker can restrict CPU load with `--cpus`, which is most likely preferable to using `CPU_USAGE_LIMIT`.
* The above examples do work with WSL2 and NVidia GPU.
* Port 31416 should **not** be publicly available, no matter whether `GUI_RPC_AUTH` is set.
