# OpenShift - Custom Ingress TLS

Set default ingress to use a custom TLS certificate instead of an OpenShift CA
signed certificate. I use this every few months to cycle my Let's Encrypt
issued certificates. ([cert-manager](https://cert-manager.io/) is a better
idea, but I have an external process to refresh my certificates.)

This chart automates the process documented
[here](https://docs.openshift.com/container-platform/4.10/security/certificates/replacing-default-ingress-certificate.html).

Chart was tested on OpenShift 4.10.8.

## Requirements

* Valid TLS certificate (PEM format), private key, and a copy of the
root CA certificate. (The root CA certificate will be included in OpenShift's
trust bundle.)
* [Patch Operator](https://github.com/redhat-cop/patch-operator)

## Install

```bash
$ make install
```

## Uninstall

I wouldn't recommend uninstalling this. If for some reason you need to, run:

```bash
$ make uninstall
```
