# Use an appropriate base image for Jetson Nano
# sudo docker build -t imswitch_hik .
# sudo docker run -it --privileged  imswitch_hik
# sudo docker ps # => get id for stop
# docker stop imswitch_hik
# sudo docker inspect imswitch_hik
# docker run --privileged -it imswitch_hik
# sudo docker run -it --rm -p 8001:8001 -p 2222:22 -e HEADLESS=1 -e HTTP_PORT=8001 -e CONFIG_FILE=example_virtual_microscope.json -e UPDATE_GIT=0 -e UPDATE_CONFIG=0 --privileged ghcr.io/openuc2/imswitch-noqt-x64:latest
# sudo docker run -it --rm -p 8001:8001 -p 2222:22 -e HEADLESS=1 -e HTTP_PORT=8001 -e CONFIG_FILE=example_uc2_hik_flowstop.json -e UPDATE_GIT=1 -e UPDATE_CONFIG=0 --privileged imswitch_hik
# performs python3 /opt/MVS/Samples/aarch64/Python/MvImport/GrabImage.py
#  sudo docker run -it -e MODE=terminal imswitch_hik
# docker build --build-arg ARCH=linux/arm64  -t imswitch_hik_arm64 .
# docker build --build-arg ARCH=linux/amd64  -t imswitch_hik_amd64 .
# sudo docker run -it --rm -p 8001:8001 -p 2222:22 -e HEADLESS=1 -e HTTP_PORT=8001 -e CONFIG_FILE=example_virtual_microscope.json -e UPDATE_GIT=0 -e UPDATE_CONFIG=0 --privileged imswitch_hik
#
# sudo docker run -it --rm -p 8001:8001 -p 2222:22 -e HEADLESS=1 -e HTTP_PORT=8001 -e CONFIG_FILE=example_uc2_hik_flowstop.json -e UPDATE_GIT=1 -e UPDATE_CONFIG=0 --privileged ghcr.io/openuc2/imswitch-noqt-x64:latest
# Use an appropriate base image for multi-arch support
FROM ubuntu:22.04

ARG TARGETPLATFORM
ENV TZ=America/Los_Angeles


# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    python3 \
    python3-pip \
    build-essential \
    git \
    mesa-utils \
    openssh-server \
    libhdf5-dev \
    nano \
    usbutils \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Download and install the appropriate Hik driver based on architecture
RUN cd /tmp && \
    wget https://www.hikrobotics.com/cn2/source/support/software/MVS_STD_GML_V2.1.2_231116.zip && \
    unzip MVS_STD_GML_V2.1.2_231116.zip && \
    if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then \
        dpkg -i MVS-2.1.2_aarch64_20231116.deb; \
    elif [ "${TARGETPLATFORM}" = "linux/amd64" ]; then \
        dpkg -i MVS-2.1.2_x86_64_20231116.deb; \
    fi
    # Copy the necessary Python script
    #RUN cd /opt/MVS/Samples/aarch64/Python/ && \
    #    cp GrabImage/GrabImage.py MvImport/GrabImage.py

RUN mkdir -p /opt/MVS/bin/fonts
# Source the bashrc file
RUN echo "source ~/.bashrc" >> ~/.bashrc
RUN /bin/bash -c "source ~/.bashrc"

# Set environment variable for MVCAM_COMMON_RUNENV
ENV MVCAM_COMMON_RUNENV=/opt/MVS/lib LD_LIBRARY_PATH=/opt/MVS/lib/64:/opt/MVS/lib/32:$LD_LIBRARY_PATH

# Install Miniforge based on architecture
RUN if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then \
        wget --quiet https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-aarch64.sh -O /tmp/miniforge.sh; \
    elif [ "${TARGETPLATFORM}" = "linux/amd64" ]; then \
        wget --quiet https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O /tmp/miniforge.sh; \
    fi && \
    /bin/bash /tmp/miniforge.sh -b -p /opt/conda && \
    rm /tmp/miniforge.sh

# Update PATH environment variable
ENV PATH=/opt/conda/bin:$PATH

# Create conda environment and install packages
RUN /opt/conda/bin/conda create -y --name imswitch python=3.10

RUN /opt/conda/bin/conda install -n imswitch -y -c conda-forge h5py numcodecs && \
    conda clean --all -f -y

# Clone the config folder
RUN git clone https://github.com/openUC2/ImSwitchConfig /root/ImSwitchConfig

# Clone the repository and install dependencies
RUN git clone https://github.com/openUC2/imSwitch /tmp/ImSwitch && \
    cd /tmp/ImSwitch && \
    git checkout NOQT && \
    /bin/bash -c "source /opt/conda/bin/activate imswitch && pip install -e /tmp/ImSwitch"

# Install UC2-REST
RUN git clone https://github.com/openUC2/UC2-REST /tmp/UC2-REST && \
    cd /tmp/UC2-REST && \
    /bin/bash -c "source /opt/conda/bin/activate imswitch && pip install -e /tmp/UC2-REST"

# Expose SSH port and HTTP port
EXPOSE 22 8001

CMD ["/bin/bash", "-c", "\
    if [ \"$MODE\" = \"terminal\" ]; then \
        /bin/bash; \
    else \
        echo 'LSUSB' && lsusb && \
        /usr/sbin/sshd -D & \
        ls /root/ImSwitchConfig && \
        if [ \"$UPDATE_GIT\" = \"true\" ]; then \
            cd /tmp/ImSwitch && \
            git pull; \
        fi && \
        if [ \"$UPDATE_INSTALL_GIT\" = \"true\" ]; then \
            cd /tmp/ImSwitch && \
            git pull && \
            /bin/bash -c 'source /opt/conda/bin/activate imswitch && pip install -e /tmp/ImSwitch'; \
        fi && \
        if [ \"$UPDATE_UC2\" = \"true\" ]; then \
            cd /tmp/UC2-REST && \
            git pull; \
        fi && \
        if [ \"$UPDATE_INSTALL_UC2\" = \"true\" ]; then \
            cd /tmp/UC2-REST && \
            git pull && \
            /bin/bash -c 'source /opt/conda/bin/activate imswitch && pip install -e /tmp/UC2-ESP'; \
        fi && \
        if [ \"$UPDATE_CONFIG\" = \"true\" ]; then \
            cd /root/ImSwitchConfig && \
            git pull; \
        fi && \
        source /opt/conda/bin/activate imswitch && \
        HEADLESS=${HEADLESS:-1} && \
        HTTP_PORT=${HTTP_PORT:-8001} && \
        CONFIG_FILE=${CONFIG_FILE:-/root/ImSwitchConfig/imcontrol_setup/example_virtual_microscope.json} && \
        USB_DEVICE_PATH=${USB_DEVICE_PATH:-/dev/bus/usb} && \
        echo \"python3 /tmp/ImSwitch/main.py --headless $HEADLESS --config-file $CONFIG_FILE --http-port $HTTP_PORT \" && \
        python3 /tmp/ImSwitch/main.py --headless $HEADLESS --config-file $CONFIG_FILE --http-port $HTTP_PORT; \
    fi"]
