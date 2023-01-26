.PHONY= check setup clean 

FLAGS= -v
FILES= cert-authority.yaml admin-client.yaml worker-node.yaml kube-controller-manager.yaml  kube-proxy.yaml kube-scheduler.yaml kube-apiserver.yaml distribute-client.yaml distribute-server.yaml

check: 
	cd playbooks && ansible-playbook ${FILES} ${FLAGS} --$@

setup: clean
	cd playbooks && ansible-playbook ${FILES} ${FLAGS}

clean:
	rm -rf cert-json/* cert-keys/*

