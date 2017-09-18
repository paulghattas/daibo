$TTL    1M
$ORIGIN doblabs.io.

openshift IN  A  192.168.1.40
master    IN  A  192.168.1.40
node1     IN  A  192.168.1.41
node2     IN  A  192.168.1.42
infra1    IN  A  192.168.1.6

*.apps    IN  CNAME master

