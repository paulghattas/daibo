$TTL    1M
$ORIGIN doblabs.io.
openshift IN  A  192.168.1.40
apollo    IN  A  192.168.1.40
helo      IN  A  192.168.1.41
starbuck  IN  A  192.168.1.42
boomer    IN  A  192.168.1.43

*.apps    IN  CNAME apollo

