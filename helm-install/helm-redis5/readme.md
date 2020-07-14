helm install --name redis5 --namespace redis -f my-values.yaml ./redis

redis-cli -h 127.0.0.1 -p 6379

redis-cli -h redis5-master-0.redis5-headless.redis.svc.cluster.local  -p 6379


redis-cli -h redis5-slave-0.redis5-headless.redis.svc.cluster.local  -p 6379

redis-cli -h redis5-slave-1.redis5-headless.redis.svc.cluster.local  -p 6379
