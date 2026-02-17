FROM prom/prometheus:latest

# Copy config + rules เข้าไปใน image
COPY ./configs/prometheus/prometheus.yml /etc/prometheus/prometheus.yml
COPY ./configs/prometheus/rules/ /etc/prometheus/rules/

# (optional) ถ้าคุณอยาก lock permission ก็ทำได้ แต่ไม่จำเป็น
