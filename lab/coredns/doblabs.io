$TTL    1800
$ORIGIN doblabs.io.

@ IN SOA dns domains (
    2012062701   ; serial
    300          ; refresh
    1800         ; retry
    14400        ; expire
    300 )        ; minimum

dns          IN  A  192.168.1.5
infra        IN  A  192.168.1.5

openshift    IN  A  192.168.1.40
master       IN  A  192.168.1.40
node1        IN  A  192.168.1.41
node2        IN  A  192.168.1.42

openshift-m  IN  A  192.168.1.51
hawkular-m   IN  A  192.168.1.51

minishift    IN  A  192.168.1.60

*.apps    IN  CNAME master
*.apps-m  IN  CNAME openshift-m

