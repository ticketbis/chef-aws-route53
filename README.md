# aws-route53

'aws-rout53' includes an LWRP to manage Route53 RR.

## LWRP

All LWRPs accepts the following parameters:

* region: Amazon region to use
* access_key_id: the access key to use
* secret_access_key: the secret to use

### entry

Manages a route53 entry

#### Parameters

* type: the RR type. Currently manages A, AAAA, CNAME, TXT and SPF. A by default.
* ttl: an integer specifying the RR TTL in seconds.
* domain: if passed, it is appended to the name to form the final RR name.
* value: an string of array of strings with the value of the RR.
* instance: the private IPv4 of the passed instance name will be the value
* eip: the EIP IPv4 value of the passed instance name will be the value
* elb: it will create a CNAME pointing to the ELB name passed

