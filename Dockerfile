FROM debian:stable-20240130-slim as install
RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt update; \
    apt -y install --no-install-recommends boinc-client \
      intel-opencl-icd mesa-opencl-icd sudo \
      boinctui bash-completion clinfo curl procps vim-tiny; \
    update-alternatives --install /usr/bin/vim vim /usr/bin/vim.tiny 0 || echo WARNING; \
    apt clean; rm -rf /var/lib/apt/lists/* /var/log/*

# Replace symbolic links
FROM install AS build
COPY start /
RUN set -eux; \
    chown boinc:boinc /etc/boinc-client/*; \
    mkdir -p /var/lib/boinc-client/locale; \
    mv /etc/boinc-client/cc_config.xml /var/lib/boinc-client/ -f; \
    mv /etc/boinc-client/global_prefs_override.xml /var/lib/boinc-client/ -f
COPY sudoers.d/50-lhcathome_boinc_theory_native /etc/sudoers.d/
RUN set -eux; chmod a-w /etc/sudoers.d/50-lhcathome_boinc_theory_native; chmod o-r /etc/sudoers.d/50-lhcathome_boinc_theory_native
USER boinc
WORKDIR /var/lib/boinc-client
ENTRYPOINT ["/start"]
CMD ["boinc", "--allow_remote_gui_rpc"]
ENV ENV=/start \
    CPU_USAGE_LIMIT=100 \
    MAX_NCPUS_PCT=100 \
    HEALTHCHECK_PATTERN=EXECUTING
HEALTHCHECK --interval=1m CMD boinccmd --get_tasks | egrep -q "${HEALTHCHECK_PATTERN}" && exit 0 || exit 1

# Tests, ensure they are run before release by copying marker file
FROM build AS test
ENV HOST_VENUE=none
RUN set -eux; \
    find /var/lib/boinc-client -type f -print0 | xargs -0r tail -n +0; \
    find /etc/boinc-client /var/lib/boinc-client -type l \
    ! -exec test -e {} \; -print | egrep . && echo "!!! broken links !!!" && exit 1 || echo "links OK"; \
    boinc --version; \
    /start boinc --show_projects; \
    test -z "$(cat /etc/boinc-client/gui_rpc_auth.cfg)"; \
    test -z "$(egrep -v '^#' /etc/boinc-client/remote_hosts.cfg)"; \
    tail -n +0 /var/lib/boinc-client/global*; grep '<host_venue></host_venue>' /var/lib/boinc-client/global_prefs_override.xml; \
    date --rfc-3339=seconds | tee /tmp/tested

# Release
FROM build
RUN test -f /var/lib/boinc-client/global_prefs.xml && echo "!!! boinc was started !!!" && exit 1 || echo OK
COPY --from=test /tmp/tested /tmp/
VOLUME /var/lib/boinc-client
EXPOSE 31416
