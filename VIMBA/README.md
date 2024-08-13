Allied Vision Alvium USB camera Dockerfile example
==================================================


## Requirements

Download the Vimba SDK, there is no direct access link for download, from
 [alliedvision.com/en/products/software.html](https://www.alliedvision.com/en/products/software.html).


## Docker

```sh
cd VIMBA
sudo docker build -t alvium:python .
```

#### Minimal working example
```sh
sudo docker run --init --privileged --rm alvium:python list_cameras.py
# -v /dev/bus/usb:/dev/bus/usb \optional
```
                  

#### Interactive session
```sh
$ sudo docker run --init -it \
                  --privileged -v /dev/bus/usb:/dev/bus/usb \
                  --entrypoint="/bin/sh" \
                  --rm \
                  alvium:python
```