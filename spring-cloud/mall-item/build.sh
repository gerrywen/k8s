docker rmi -f hub.gerrywen.com/library/mall/mall-item-server:$1
docker rmi -f mall/mall-item-server
docker build -t mall/mall-item-server .
docker tag mall/mall-item-server:latest hub.gerrywen.com/library/mall/mall-item-server:$2
docker push hub.gerrywen.com/library/mall/mall-item-server:$2