Creating an NFS Instance on AWS EC2 with Vagrant &amp; Chef
===========================================================

This repository is part of [this blog post](http://jeqo.github.io/blog/devops/2014/11/24/2014-11-21-create-nfs-instance-aws/).

## Description

Create a Vagrant + Chef configuration to create a AWS EC2 instance with NFS. Why? Because I want to use this instance as a NFS server to share directories with large files.

## How to use it?

1. Install these software:
  * [Vagrant](http://vagrantup.com): Virtual Machine provider
  * [Vagrant AWS Plug-in](https://github.com/mitchellh/vagrant-aws): integrate Vagrant with AWS EC2
  * [Vagrant Omnibus Plug-in](https://github.com/opscode/vagrant-omnibus): Omnibus to install Chef client
  * [Chef SDK](https://downloads.getchef.com/chef-dk/): to upload Chef artifacts
  * (Optional) [VirtualBox](https://www.virtualbox.org/): if you want to test it locally
2. Configure the following accounts:
  * Chef Server (or [Cloud](https://manage.opscode.com)): for provisioning
  * [AWS](http://aws.amazon.com) account: to create EC2 instances
3. Fork this repository
4. Configure your AWS credentials (*aws.properties*)
5. Upload Chef cookbooks and roles
6. Update and run Vagrant configuration

### Configure your AWS credential

If you have downloaded the repository, you should have the following structure:

![repository structure](https://raw.githubusercontent.com/jeqo/jeqo.github.io/master/assets/images/vagrant-aws-chef-nfs/2014-11-25_1149.png)

Where boxes are Vagrant configurations and chef-repo is the Chef repository with 3 cookbooks (line and nfs downloaded from Chef Supermarket) and 2 roles: one for NFS Server and other for NFS Clients.

You should add the following file to your *aws directory* "boxes/aws":

```ruby
keys:
  access_key_id: [access key id]
  secret_access_key:[secret access key]
  key_pair_location: [path to <key_pair>.pem]
```

### Upload Chef cookbooks and roles

You should upload Chef artifacts to consume them from AWS instance. If you try it locally, you don't need to update them.

1. Copy *cookbooks* and *roles* directories on you *chef-repo* directory from your Chef Starter Kit. (To learn more about Chef: [Learn Chef](https://learn.getchef.com))

2. Upload your artifacts using *knife* tool:

```bash
cd [chef-repo directory]
knife upload *
```

### Update and run Vagrant configuration

Now that you have your Chef recipes online, you can configure your Vagrant files:

Vagrantfile:

```ruby
# To load properties files
require "yaml"

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Load box properties
  props = YAML.load_file("box.properties")
  # Load AWS properties (credentials)
  aws_props = YAML.load_file("../aws.properties")

  config.vm.box = "#{props['box']['name']}"
  # Target to aws.box file that only contains AMI id (is not used)
  config.vm.box_url = "file://#{props['box']['base_location']}"

  config.vm.provider :aws do |aws, override|
    # Set AWS credentials
    aws.access_key_id = "#{aws_props['keys']['access_key_id']}"
    aws.secret_access_key = "#{aws_props['keys']['secret_access_key']}"
    aws.keypair_name = "jeqo"

    # Set instance configurations - define it depending on your requirements
    aws.instance_type = "t2.micro"
    aws.region = "us-east-1"
    aws.availability_zone = "us-east-1a"
    aws.ami = "ami-9eaa1cf6"

    override.ssh.username = "ubuntu"
    override.ssh.private_key_path = "#{aws_props['keys']['key_pair_location']}"

    aws.tags = {
      'Name' => "#{props['box']['name']}"
    }

    # Define storage
    aws.block_device_mapping = [{
      'DeviceName' => '/dev/sda1',
      'Ebs.VolumeSize' => props['box']['disk_size']
      }]

    # Define security group (inbound ports that should be open: TCP: 111, 2049, 32768, 44182, 54508 and UDP: 111, 2049, 32768, 32770-32800)
    aws.security_groups = "nfs-group"

    config.ssh.pty = true
  end

  # Instal last chef client software  
  config.omnibus.chef_version = :latest

  # Increment SWAP on AWS EC2 Instance
  config.vm.provision "shell" do |s|
    s.path	= "increase_swap.sh"
  end

  # Chef server configuration
  config.vm.provision "chef_client" do |chef|
    chef.chef_server_url = "https://api.opscode.com/organizations/[organization]"
    chef.validation_client_name = "[organization]-validator"
    chef.validation_key_path = "#{props['chef']['repo_location']}/.chef/[organization]-validator.pem"
    chef.node_name = "#{props['box']['name']}"
    # Role uploaded to configure NFS Server
    chef.add_role "nfs-server"
  end
end

```

It's important to follow [these recommendations](https://theredblacktree.wordpress.com/2013/05/23/how-to-setup-a-amazon-aws-ec2-nfs-share/) to create AWS EC2 Security Group.

### Demo

You can check how to use it in this video:

TODO: upload youtube video

> **Note**: If you want to test locally, you need to download [this box](https://oss-binaries.phusionpassenger.com/vagrant/boxes/latest/ubuntu-14.04-amd64-vbox.box) for NFS Server (Ubuntu) and [this one](https://storage.us2.oraclecloud.com/v1/istoilis-istoilis/vagrant/oel65-64.box) for NFS Client (Oracle Linux) and change box url on *box.properties* file.
