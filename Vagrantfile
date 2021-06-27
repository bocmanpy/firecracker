# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.

  # Provider-specific configuration 
  # Docs: https://github.com/vagrant-libvirt/vagrant-libvirt#vagrant-project-preparation
  config.vm.define :firecracker do |domain|
    # Vagrant options
    domain.vm.box = "generic/ubuntu2004"
    domain.vm.provider :libvirt do |libvirt|
      libvirt.cpus = 4
      libvirt.nested = true
      libvirt.memory = 8192
    end
  end

  # Upload repository kernel
  config.vm.provision "file", source: "data/kernel/linux-5.12.13", destination: "/tmp/vmlinux"

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", path: "startup.sh"

end
