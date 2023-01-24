.PHONY= plan validate fmt apply init clean

plan: init fmt validate
	terraform $@

validate:
	terraform $@

fmt:
	terraform $@

apply: fmt validate 
	terraform $@ --auto-approve

init:
	terraform $@

clean:
	terraform destroy --auto-approve
	rm -rf .terraform*
	
