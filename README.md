# docker-boinc-client

A Docker image for the [BOINC client](https://packages.debian.org/stable/boinc-client).

This image does not include the GUI client and should be used via [boinccmd](https://manpages.debian.org/stable/boinc-client/boinccmd.1.en.html) or with [boinctui](https://packages.debian.org/stable/boinctui) (included for convenience).

When the GUI RPC Port is routed, it is also possible to control the client remotely with [BOINC Manager](https://boinc.berkeley.edu/wiki/BOINC_Manager) or the above tools.

## Volumes

| Path                    |                             |
|-------------------------|------------------------------
| `/var/lib/boinc-client` | Data and settings for BOINC |

## Ports

| Port  |              |
|-------|---------------
| 31416 | GUI RPC port |

## Supported settings

| Environment Variable | Default |                                                     |
|----------------------|---------|-----------------------------------------------------|
| `GUI_RPC_AUTH`       | ` `     | The password for GUI RPC, empty means no password   |

## Download

```
docker pull ghcr.io/mentalfs/boinc-client
```

## Example

Starting:
```bash
docker run --name boinc \
  -e GUI_RPC_AUTH="correct horse battery staple" \
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

* The client will start with `--allow_remote_gui_rpc`, allowing all hosts to connect to the GUI RPC.
* Port 31416 should **not** be publicly available, especially not without `GUI_RPC_AUTH` set.
* GPUs are usable with `--gpus`, `--privileged` (not recommended) or `--device /dev/dri:/dev/dri` depending on GPU model.
* The above examples do work with WSL2 and NVidia GPU.
