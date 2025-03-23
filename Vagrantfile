# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  if `uname -m`.chomp == "arm64"
    puts "Running on Apple Silicon - Using QEMU"
    config.vagrant.plugins = "vagrant-qemu"
    config.vm.box = "cloud-image/ubuntu-24.04"
    config.vm.box_version = "20240423.0.0"
    config.disksize.size = "20GB"

    config.vm.provider "qemu" do |qemu|
      qemu.memory = "4096"
      qemu.cpus = 2
      qemu.cpu = "cortex-a72"
      qemu.machine = "virt"
      qemu.qemu_binary = "/opt/homebrew/bin/qemu-system-aarch64"  # Explicit path
      qemu.qemu_img_binary = "/opt/homebrew/bin/qemu-img" 
      qemu.netdev_user_hostfwd = "hostfwd=tcp::2222-:22"
    end
  else
    puts "Running on Intel - Using VirtualBox"
    config.vm.box = "generic/ubuntu2404"

    config.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"
      vb.cpus = 2
    end
  end

  config.vm.network "forwarded_port", guest: 80, host: 8081
  config.vm.network "private_network", type: "dhcp"

  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Ansible Provisioning
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "site.yml"
    ansible.inventory_path = "inventory.ini"
    ansible.limit = "vagrant"
    ansible.extra_vars = {
      target_hosts: "vagrant"
    }
    ansible.verbose = "v"
  end

end



