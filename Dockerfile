FROM debian:stable-20240130-slim

RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt update; \
    apt -y install --no-install-recommends boinc-client \
      bash-completion boinctui intel-opencl-icd mesa-opencl-icd; \
    apt clean; rm -rf /var/lib/apt/lists/* /var/log/*

RUN set -eux; \
    chown boinc:boinc /etc/boinc-client/*; \
    mkdir -p /var/lib/boinc-client/locale; \
    mv /etc/boinc-client/cc_config.xml /var/lib/boinc-client/ -f; \
    mv /etc/boinc-client/global_prefs_override.xml /var/lib/boinc-client/ -f; \
    find /etc/boinc-client /var/lib/boinc-client -type l \
    ! -exec test -e {} \; -print | egrep . && echo "!!! broken links !!!" && exit 1 || echo OK

COPY start /
ENTRYPOINT ["/start"]
USER boinc
WORKDIR /var/lib/boinc-client
CMD ["boinc", "--allow_remote_gui_rpc"]

RUN set -eux; \
    boinc --version; \
    /start boinc --show_projects; \
    test -z "$(cat /etc/boinc-client/gui_rpc_auth.cfg)"; \
    test -z "$(egrep -v '^#' /etc/boinc-client/remote_hosts.cfg)"

VOLUME /var/lib/boinc-client
EXPOSE 31416
