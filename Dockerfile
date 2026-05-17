FROM ghcr.io/astral-sh/uv:0.11.6-python3.13-trixie@sha256:b3c543b6c4f23a5f2df22866bd7857e5d304b67a564f4feab6ac22044dde719b AS uv_source
FROM docker.io/tianon/gosu:1.19-trixie@sha256:3b176695959c71e123eb390d427efc665eeb561b1540e82679c15e992006b8b9 AS gosu_source

FROM quay.io/opendevorg/python-builder:3.12-trixie AS builder

# Disable Python stdout buffering to ensure logs are printed immediately
ENV PYTHONUNBUFFERED=1
WORKDIR /tmp/src

COPY --chmod=0755 --from=uv_source /usr/local/bin/uv /usr/local/bin/uvx /usr/local/bin/

COPY . /tmp/src

RUN uv export --format requirements.txt --output-file requirements.txt --no-hashes --no-emit-project
# Add anthropic and matrix depends
RUN python tools/print-deps.py -a requirements.txt provider.anthropic platform.matrix

RUN assemble

FROM quay.io/opendevorg/python-base:3.12-trixie as hermes

COPY --chmod=0755 --from=gosu_source /gosu /usr/local/bin/

RUN --mount=from=builder,source=/output,target=/output /output/install-from-bindep

COPY .env.example cli-config.yaml.example /usr/local/share/hermes/
COPY docker/SOUL.md /usr/local/share/hermes/docker/SOUL.md
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY skills /usr/local/share/hermes/skills/
COPY tools/skills_sync.py /usr/local/share/hermes/tools/skills_sync.py

# Start as root so the entrypoint can usermod/groupmod + gosu.
# If HERMES_UID is unset, the entrypoint drops to the default hermes user (10000).

# ---------- Runtime ----------
ENV HERMES_HOME=/opt/data
ENV PATH="/opt/data/.local/bin:${PATH}"
ENV HERMES_BUNDLED_SKILLS=/usr/local/share/hermes/skills
ENV HERMES_INSTALL_DIR=/usr/local/share/hermes
VOLUME [ "/opt/data" ]
ENTRYPOINT [ "/usr/bin/tini", "-g", "--", "/usr/local/bin/entrypoint.sh" ]
