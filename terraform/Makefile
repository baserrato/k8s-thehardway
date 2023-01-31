.PHONY= plan validate fmt apply init clean destroy

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

destroy:
	terraform $@ --auto-approve

clean: destroy
	rm -rf .terraform*
	
