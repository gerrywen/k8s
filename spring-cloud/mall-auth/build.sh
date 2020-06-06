docker rmi -f hub.gerrywen.com/library/mall/mall-authentication-service:$1
docker rmi -f mall/mall-authentication-server
docker build -t mall/mall-authentication-server .
docker tag mall/mall-authentication-server:latest hub.gerrywen.com/library/mall/mall-authentication-server:$2
docker push hub.gerrywen.com/library/mall/mall-authentication-server:$2