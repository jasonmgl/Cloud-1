ANSIBLE_CONFIG_FILE=ansible/ansible.cfg

all: up

re: destroy up

up:
	./scripts/install.sh
	./scripts/login_aws.sh
	./scripts/init_terraform.sh
	./scripts/provision_ec2.sh
	./scripts/init_ansible.sh

down:
	mise exec -- terraform -chdir=terraform apply -auto-approve -invoke=action.aws_ec2_stop_instance.force_stop

clean:
	rm -f ansible/inventory.ini ansible/inventory.yaml

destroy: clean
	./scripts/destroy.sh

uninstall:
	./scripts/uninstall.sh

fclean: destroy uninstall
	rm -rf terraform/.terraform/ terraform/terraform.tfstate* .ansible/

test:
	ANSIBLE_CONFIG=$(ANSIBLE_CONFIG_FILE) ansible aws -m ping

provision:
	ANSIBLE_CONFIG=$(ANSIBLE_CONFIG_FILE) ansible-playbook -i ansible/inventory.yaml ansible/playbook.yaml

reboot:
	ANSIBLE_CONFIG=$(ANSIBLE_CONFIG_FILE) ansible aws -m reboot --become

check-cert:
	./scripts/check_cert.sh

help:
	@tail -n 1 ./Makefile |  sed -e 's/.PHONY:/Commands:/g'

.PHONY: re up down clean destroy uninstall fclean test provision help
