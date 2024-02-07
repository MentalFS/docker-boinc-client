FROM debian:stable-20240130-slim as install
RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt update; \
    apt -y install --no-install-recommends boinc-client \
      intel-opencl-icd mesa-opencl-icd \
      boinctui bash-completion clinfo procps vim-tiny; \
    update-alternatives --install /usr/bin/vim vim /usr/bin/vim.tiny 0 || echo WARNING; \
    apt clean; rm -rf /var/lib/apt/lists/* /var/log/*

# Replace symbolic links
FROM install AS build
RUN set -eux; \
    chown boinc:boinc /etc/boinc-client/*; \
    mkdir -p /var/lib/boinc-client/locale; \
    mv /etc/boinc-client/cc_config.xml /var/lib/boinc-client/ -f; \
    mv /etc/boinc-client/global_prefs_override.xml /var/lib/boinc-client/ -f
COPY start /
ENTRYPOINT ["/start"]
ENV ENV=/start
USER boinc
WORKDIR /var/lib/boinc-client
CMD ["boinc", "--allow_remote_gui_rpc"]

# Tests, ensure they are run before release by copying marker file
FROM build AS test
RUN set -eux; \
    find /var/lib/boinc-client -type f -print0 | xargs -0r tail -n +0; \
    find /etc/boinc-client /var/lib/boinc-client -type l \
    ! -exec test -e {} \; -print | egrep . && echo "!!! broken links !!!" && exit 1 || echo "links OK"; \
    boinc --version; \
    /start boinc --show_projects; \
    test -z "$(cat /etc/boinc-client/gui_rpc_auth.cfg)"; \
    test -z "$(egrep -v '^#' /etc/boinc-client/remote_hosts.cfg)"; \
    date --rfc-3339=seconds | tee /tmp/tested

# Release
FROM build
COPY --from=test /tmp/tested /tmp/
VOLUME /var/lib/boinc-client
EXPOSE 31416
