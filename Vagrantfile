# -*- mode: ruby -*-
# vi: set ft=ruby :

require "yaml"

require File.expand_path("./scripts/homestead.rb")
hs = Homestead.create("./homestead.yml")

Vagrant.require_version ">= 1.8.4"
Vagrant.configure("2") do |conf|
  hs.configure(conf)
end
