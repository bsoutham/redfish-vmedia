# redfish-vmedia

You need to modify the mount.sh and unmount.sh
Modify these 3 values at the top of each file for your target server.
  ILO_IP=
  ILO_USER=
  ILO_PASSWORD=

for vmedia_mount.sh you also need to modify:
    ISO_URL=

Examples look like:
  ILO_IP=192.168.1.2
  ILO_USER="administrator"
  ILO_PASSWORD="supersecret"
  ISO_URL="http://192.168.1.2:8000/iso/esxi.ISO"


## nginx usage
To setup nginx for serving an iso:
1. `cd nginx/`
2. copy the iso image to boot into the nginx/iso directory
3. `docker run --rm -v "$(pwd)"/iso:/usr/share/nginx/html/iso -p 8000:80 $(docker build -q .)`


After docker is running in one terminal and the mount/unmount files have the parameters modified
you can simply run `mount.sh` to mount the ISO to the server, set boot from the ISO next boot and power on the server.

A succssful run will look like:

```
Attempting Login to iLO at 192.168.86.50
Found ISO IMAGE: http://192.168.86.202:8000/iso/esxi.ISO
Virtual Media already mounted
Mounted vMedia
Powering On server ....
```

debug logging will be written to `log.log` where mount/unmount commands are run
