docker rmi -f hub.gerrywen.com/library/mall/mall-gateway-service:$1
docker rmi -f mall/mall-gateway-server
docker build -t mall/mall-gateway-server .
docker tag mall/mall-gateway-server:latest hub.gerrywen.com/library/mall/mall-gateway-server:$2
docker push hub.gerrywen.com/library/mall/mall-gateway-server:$2