FROM innovanon/builder as bootstrap
RUN sleep 91                                                                                                 \
 && curl -L --proxy $SOCKS_PROXY                     -o void-x86_64-musl-ROOTFS-20191109.tar.xz              \
       https://alpha.de.repo.voidlinux.org/live/current/void-x86_64-musl-ROOTFS-20191109.tar.xz              \
 && tar xf                                              void-x86_64-musl-ROOTFS-20191109.tar.xz -C /tmp/

FROM scratch as voidlinux
COPY --from=bootstrap /tmp/ /

FROM voidlinux as droidlinux
COPY --from=bootstrap /etc/profile.d/support.sh      /etc/profile.d/
COPY --from=bootstrap /etc/sysctl.conf               /etc/sysctl.conf
COPY --from=bootstrap /usr/local/bin/support         /usr/local/bin/
RUN xbps-install -Suy \
 && xbps-install   -y tor
COPY                 ./etc/profile.d/socksproxy.sh   /etc/profile.d/
COPY                 ./etc/xbps.d/                   /etc/xbps.d/
COPY                 ./usr/local/bin/support-wrapper /usr/local/bin/
SHELL ["/usr/bin/bash", "-l", "-c"]
ARG TEST
ENV TEST=$TEST
RUN tor --verify-config \
 && sleep 91            \
 && xbps-install -S

FROM scratch as squash
COPY --from=droidlinux / /
SHELL ["/usr/bin/bash", "-l", "-c"]
ARG TEST
ENV TEST=$TEST

FROM squash as test
ARG TEST
ENV TEST=$TEST
RUN tor --verify-config \
 && sleep 127           \
 && xbps-install -S     \
 && exec true || exec false

FROM squash as final

