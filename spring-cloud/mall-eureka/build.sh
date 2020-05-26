docker rmi -f hub.gerrywen.com/library/mall/mall-eureka-server:$1
docker rmi -f mall/mall-eureka-server
docker build -t mall/mall-eureka-server .
docker tag mall/mall-eureka-server:latest hub.gerrywen.com/library/mall/mall-eureka-server:$2
docker push hub.gerrywen.com/library/mall/mall-eureka-server:$2