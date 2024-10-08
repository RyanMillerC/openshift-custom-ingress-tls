.PHONY: install uninstall

install:
	helm install \
	    --namespace openshift-config \
	    ingress-custom-tls .

upgrade:
	helm upgrade \
	    --namespace openshift-config \
	    ingress-custom-tls .

uninstall:
	helm uninstall \
	     --namespace openshift-config \
	     ingress-custom-tls
