.PHONY= plan validate fmt apply init

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
