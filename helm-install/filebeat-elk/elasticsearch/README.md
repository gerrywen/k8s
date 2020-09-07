### 运行命令
helm install --name elasticsearch --namespace logs -f my-values.yaml ./elasticsearch 

### 运行命令完成信息如下：

NAME:   elasticsearch
LAST DEPLOYED: Fri Aug  7 03:00:46 2020
NAMESPACE: logs
STATUS: DEPLOYED

RESOURCES:
==> v1/Pod(related)
NAME                    READY  STATUS    RESTARTS  AGE
elasticsearch-master-0  0/1    Init:0/1  0         <invalid>

==> v1/Service
NAME                           TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)            AGE
elasticsearch-master           ClusterIP  10.106.238.200  <none>       9200/TCP,9300/TCP  <invalid>
elasticsearch-master-headless  ClusterIP  None            <none>       9200/TCP,9300/TCP  <invalid>

==> v1/StatefulSet
NAME                  READY  AGE
elasticsearch-master  0/1    <invalid>

==> v1beta1/PodDisruptionBudget
NAME                      MIN AVAILABLE  MAX UNAVAILABLE  ALLOWED DISRUPTIONS  AGE
elasticsearch-master-pdb  N/A            1                0                    <invalid>


NOTES:
1. Watch all cluster members come up.
  $ kubectl get pods --namespace=logs -l app=elasticsearch-master -w
2. Test cluster health using Helm test.
  $ helm test elasticsearch --cleanup