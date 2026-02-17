FROM grafana/promtail:main-3b44b80

ARG ENV_NAME=office

COPY ./configs/promtail/${ENV_NAME}/promtail.yml /etc/promtail/promtail.yml

ENTRYPOINT ["/usr/bin/promtail"]
CMD ["-config.file=/etc/promtail/promtail.yml"]
