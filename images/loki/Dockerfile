FROM grafana/loki:main-3b44b80

ARG ENV_NAME=office

COPY ./configs/loki/${ENV_NAME}/loki.yml /etc/loki/loki.yml

ENTRYPOINT ["/usr/bin/loki"]
CMD ["-config.file=/etc/loki/loki.yml"]
