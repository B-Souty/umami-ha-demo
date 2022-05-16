# Umami High Availability Stack

## Introduction

the goal of this repo is to investigate how to deploy a high availability Umami.

It relies on a 3 node umami setup backed by an HA Postgresql database and load balanced by an nginx proxy.

This whole setup is defined using IaC (Terraform and Ansible).

## Deploying the solution

### AWS Region

In its current state, the solution will be deployed in the `eu-west-1` region. 

This can be manually updated in a few places in the Terraform manifests as well as in the Ansible ones. I will try to make this more easily configurable in the future.

### Infrastructure

We first need to deploy the infrastructure by applying the terraform scripts.

Navigate to the terraform directory.

```
cd ./terraform
```

Run `terrform init` to download the required modules (only needed for the first run).

Update the values in the `variables.tf` file.

| Variable name | default          | description                                                          |
|---------------|------------------|----------------------------------------------------------------------|
| ssh-whitelist | `["1.2.3.4/32"]` | List of IP addresses/subnets allowed to connect to the node via SSH. |
| kms-key-name  |  `kms-key-name`  | Name of the KMS key name to use to access EC2 instances.             |

Finally apply the terraform scripts with:

```
terraform apply
```

Terraform will create the following infra:

- 1 EC2 instance to host the nginx proxy
- 1 ASG with 3 instances to host the Umami servers
- 1 RDB database
- VPC, Subnets, Secret, Security groups, ...

### Configure the stack

Using Ansible, we will then configure the different servers making up the stack.

navigate to the ansible directory.

```
cd ./ansible
```

You can start by listing the inventory to make sure Ansible is correctly picking up the infra setup by terraform.

```
ansible-inventory -i inventory --list
```

At the end of the output you should see something similar to the example below:

```console
    .....
    "all": {
        "children": [
            "aws_ec2",
            "nginx",
            "umami_server",
            "ungrouped"
        ]
    },
    "aws_ec2": {
        "hosts": [
            "ec2-11-22-33-10.eu-west-1.compute.amazonaws.com",
            "ec2-11-22-33-11.eu-west-1.compute.amazonaws.com",
            "ec2-11-22-33-12.eu-west-1.compute.amazonaws.com",
            "ec2-11-22-33-13.eu-west-1.compute.amazonaws.com"
        ]
    },
    "nginx": {
        "hosts": [
            "ec2-11-22-33-10.eu-west-1.compute.amazonaws.com"
        ]
    },
    "umami_server": {
        "hosts": [
            "ec2-11-22-33-11.eu-west-1.compute.amazonaws.com",
            "ec2-11-22-33-12.eu-west-1.compute.amazonaws.com",
            "ec2-11-22-33-13.eu-west-1.compute.amazonaws.com"
        ]
    }
}
```

Once you confirmed your nodes are correctly being picked up, you can apply the configurations by running the ansible playbooks.

#### Installing Umami

To install Umami on the 3 umami server run the `umami-servers` playbook.

```
ansible-playbook umami-servers.yml -i inventory
```

#### Prepare the database - WIP - Manual step required

There is one manual step currently required to finish setting up the umami servers. We need to initialize the database. Umami provides a [SQL script](https://github.com/mikecao/umami/tree/master/sql) to execute to achieve that.

At the moment, we need to SSH into one of the umami instance we just provisioned and execute the script from there.

retrieve the database password using aws cli

```
aws secretsmanager get-secret-value --secret-id umami_db_password --region <your_region>
```

SSH into one of the umami server instance and execute the provided script.

```
psql -U psqladm -d umami -h umami.abcdefghijk.eu-west-1.rds.amazonaws.com -f /var/analytics/umami/sql/schema.postgresql.sql
```


#### Installing Nginx load balancer

To install the nginx proxy on the remaining instance, run the `ninx-proxy` playbook.

```
ansible-playbook nginx-proxy.yml -i inventory
```

## Accessing Umami

Once the stack has been deployed and configured, you can access Umami by navigating to the public dns name of the nginx EC2 instance. In case you can't find it anymore, you can retrieve it by running the `ansible-inventory` command or using `awscli`

```
ansible-inventory -i inventory/nginx_proxy.aws_ec2.yml --list

# or

aws ec2 describe-instances --filters "Name=tag-value,Values=nginx-proxy"  --query 'Reservations[*].Instances[*].{Instance:PublicDnsName}'
```

Upong navigating to Umami, you will see a security prompt. This is because for the sake of demonstration this stack was setup using a self-signed certificate. Add an exception to your browser and access Umami. You can login to your instance by using the default credentials `admin:umami`
