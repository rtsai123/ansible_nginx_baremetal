# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  arch = `uname -m`.strip

  if arch == "arm64"
    puts "Running on Apple Silicon - Using QEMU"
    config.vagrant.plugins = "vagrant-qemu"
    config.vm.box = "cloud-image/ubuntu-24.04"
    config.vm.box_version = "20240423.0.0"

    config.vm.provider "qemu" do |qemu|
      qemu.memory = "4096"
      qemu.cpus = 2
      qemu.cpu = "cortex-a72"
      qemu.machine = "virt"
      qemu.qemu_binary = "/opt/homebrew/bin/qemu-system-aarch64"
      qemu.qemu_img_binary = "/opt/homebrew/bin/qemu-img"
      qemu.qemu_dir = "/opt/homebrew/opt/qemu/share/qemu"
      qemu.netdev_user_hostfwd = "hostfwd=tcp::2222-:22"
    end

  elsif arch == "x86_64"
    puts "Running on Intel Mac - Using VirtualBox"
    config.vm.box = "bento/ubuntu-24.04"

    config.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"
      vb.cpus = 2
    end

  else
    raise "Unsupported architecture: #{arch}"
  end

  # Networking
  config.vm.network "forwarded_port", guest: 80, host: 8081
  config.vm.network "private_network", type: "dhcp"
  config.vm.synced_folder ".", "/vagrant", disabled: true

end

