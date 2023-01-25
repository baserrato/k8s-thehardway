.PHONY= all setup clean 

FLAGS= -v


FILES= cert-authority.yaml admin-client.yaml worker-node.yaml kube-controller-manager.yaml  kube-proxy.yaml kube-scheduler.yaml

all: clean setup


setup:
	cd playbooks && ansible-playbook ${FILES} ${FLAGS}

clean:
	rm -rf cert-json/* cert-keys/*

