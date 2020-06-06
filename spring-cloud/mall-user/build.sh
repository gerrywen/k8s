docker rmi -f hub.gerrywen.com/library/mall/mall-user-service:$1
docker rmi -f mall/mall-user-server
docker build -t mall/mall-user-server .
docker tag mall/mall-user-server:latest hub.gerrywen.com/library/mall/mall-user-server:$2
docker push hub.gerrywen.com/library/mall/mall-user-server:$2