FROM debian:trixie

ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive

# Install systemd and python3 (python3-apt is needed by ansible's apt module)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dbus \
        python3 \
        python3-apt \
        sudo \
        systemd \
        systemd-sysv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Mask services that cannot run inside a container
RUN systemctl mask \
    console-getty.service \
    dev-hugepages.mount \
    getty.target \
    sys-kernel-debug.mount \
    sys-kernel-tracing.mount \
    systemd-remount-fs.service \
    systemd-udevd-control.socket \
    systemd-udevd-kernel.socket \
    systemd-udevd.service

# Create the videoteam user expected by the playbook (user_name default)
RUN useradd -m -s /bin/bash videoteam && \
    echo 'videoteam ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/videoteam && \
    chmod 0440 /etc/sudoers.d/videoteam

# systemd expects SIGRTMIN+3 to initiate a clean shutdown
STOPSIGNAL SIGRTMIN+3
CMD ["/lib/systemd/systemd"]
