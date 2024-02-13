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
RUN  mkdir -p /var/lib/boinc-client/locale
COPY start /
USER boinc
WORKDIR /var/lib/boinc-client
ENTRYPOINT ["/start"]
CMD ["boinc", "--allow_remote_gui_rpc"]
ENV ENV=/start \
    CPU_USAGE_LIMIT=100 \
    X_NCPUS_PCT=100 \
    HEALTHCHECK_PATTERN=EXECUTING
HEALTHCHECK --interval=1m CMD boinccmd --get_tasks | egrep -q "${HEALTHCHECK_PATTERN}" && exit 0 || exit 1

# Tests, ensure they are run before release by copying marker file
FROM build AS test
ENV HOST_VENUE=none
RUN set -eux; \
    find /etc/boinc-client /var/lib/boinc-client -type f -print0 | xargs -0r tail -vn +0; \
	ls -lha /etc/boinc-client /var/lib/boinc-client; \
    boinc --version; \
	rm -f /var/lib/boinc-client/global_prefs_override.xml; \
	echo OLD > /var/lib/boinc-client/global_prefs_override.xml; \
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
