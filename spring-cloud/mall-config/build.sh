docker rmi -f hub.gerrywen.com/library/mall/mall-config-server:$1
docker rmi -f mall/mall-config-server
docker build -t mall/mall-config-server .
docker tag mall/mall-config-server:latest hub.gerrywen.com/library/mall/mall-config-server:$2
docker push hub.gerrywen.com/library/mall/mall-config-server:$2