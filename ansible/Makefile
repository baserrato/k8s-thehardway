.PHONY= all setup clean 

FLAGS= -v

FILES= cert-authority.yaml admin-client.yaml

all: clean setup test-step

setup:
	cd playbooks && ansible-playbook ${FILES} ${FLAGS}

clean:
	rm -rf certs-json/* cert-keys/*
