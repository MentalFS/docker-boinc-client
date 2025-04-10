FROM debian:stable-20250407-slim AS install
RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt update; \
    for P in ca-certificates curl gnupg python3 libgl1 ocl-icd-libopencl1 libquadmath0 bash bash-completion boinctui vim-tiny; do \
      apt -y install --no-install-recommends "${P}" || echo "ERROR: Could not install ${P}"; \
    done; \
    update-alternatives --install /usr/bin/vim vim /usr/bin/vim.tiny 0 || echo WARNING; \
    apt clean; rm -rf /var/lib/apt/lists/* /var/log/*
ARG BOINC_REPO=stable
RUN test -n "${BOINC_REPO}" \
    && export DEBIAN_CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")" \
    && curl -fsSL "https://boinc.berkeley.edu/dl/linux/${BOINC_REPO}/${DEBIAN_CODENAME}/boinc.gpg" \
       | gpg --dearmor -o /etc/apt/keyrings/boinc.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/boinc.gpg] https://boinc.berkeley.edu/dl/linux/${BOINC_REPO}/${DEBIAN_CODENAME} ${DEBIAN_CODENAME} main" | tee /etc/apt/sources.list.d/boinc.list \
    || echo "installing boinc from Debian ${DEBIAN_CODENAME} repository"
RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    export DEBIAN_CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"; \
    addgroup --quiet --system boinc; \
    adduser --quiet --system --ingroup boinc --home /var/lib/boinc-client --gecos "BOINC core client" boinc; \
    apt update; \
    apt -y install --no-install-recommends boinc-client; \
    apt clean; rm -rf /var/lib/apt/lists/* /var/log/*

# Replace symbolic links and configure image
FROM install AS build
RUN set -eux; \
    mkdir -p /var/lib/boinc-client/locale; \
    test -L "/var/lib/boinc" && rm -f "/var/lib/boinc"; \
    test -d "/var/lib/boinc" && mv /var/lib/boinc/* "/var/lib/boinc-client/"; \
    rm -rf "/var/lib/boinc"; ln -s "/var/lib/boinc-client" "/var/lib/boinc"; \
    rm -rf "/etc/boinc-client"; ln -s "/var/lib/boinc-client" "/etc/boinc-client"; \
    chown -R boinc:boinc "/var/lib/boinc-client"; \
    mkdir -p "/etc/OpenCL/vendors" \
    && test -f "/etc/OpenCL/vendors/nvidia.icd" \
    || echo "libnvidia-opencl.so.1" > "/etc/OpenCL/vendors/nvidia.icd"
COPY start /
USER boinc
WORKDIR /var/lib/boinc-client
ENTRYPOINT ["/start"]
CMD ["boinc"]
ENV ENV=/start \
    CPU_USAGE_LIMIT=99 \
    SUSPEND_CPU_USAGE=0.0 \
    MAX_NCPUS_PCT=100 \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
HEALTHCHECK --interval=1m CMD \
    find /proc/1 -maxdepth 0 "!" -newermt "${START_DELAY:-60} seconds ago" -exec false {} + \
    || boinccmd --get_task_summary sprce | tee /dev/stderr | egrep -q '^executing|^suspended' 2>&1 || exit 1

# Tests, ensure they are run before release by copying marker file
FROM build AS test
ENV HOST_VENUE=none
RUN set -eux; \
    find /etc/boinc-client /var/lib/boinc /var/lib/boinc-client -type f -print0 | xargs -0r tail -vn +0; \
	ls -lha /etc/boinc-client /var/lib/boinc /var/lib/boinc-client; \
    boinc --version; \
	rm -f /var/lib/boinc-client/global_prefs_override.xml; \
	echo OLD > /var/lib/boinc-client/global_prefs_override.xml; \
    /start boinc --show_projects; \
    test -z "$(cat /var/lib/boinc-client/gui_rpc_auth.cfg)"; \
    tail -n +0 /var/lib/boinc-client/global*; grep '<host_venue></host_venue>' /var/lib/boinc-client/global_prefs_override.xml; \
    find /etc/boinc-client -type f -print0 | xargs -0r tail -vn +0; \
    id; test "uid=100(boinc) gid=101(boinc) groups=101(boinc),44(video)" = "$(id)"; \
    date --rfc-3339=seconds | tee /tmp/tested

# Release
FROM build
RUN test -f /var/lib/boinc-client/global_prefs.xml && echo "!!! boinc was started !!!" && exit 1 || echo OK
COPY --from=test /tmp/tested /tmp/
VOLUME /var/lib/boinc-client
EXPOSE 31416
