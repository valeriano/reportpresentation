sudo docker run -d \
--name grafana \
-p 3003:3003 \
-p 3004:8083 \
-p 8086:8086 \
-p 22022:22 \
-p 8125:8125/udp \
grafana:latest
