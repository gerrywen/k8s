docker rmi -f hub.gerrywen.com/library/mall/mall-order-server:$1
docker rmi -f mall/mall-order-server
docker build -t mall/mall-order-server .
docker tag mall/mall-order-server:latest hub.gerrywen.com/library/mall/mall-order-server:$2
docker push hub.gerrywen.com/library/mall/mall-order-server:$2