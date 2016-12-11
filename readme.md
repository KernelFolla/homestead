# Laravel Homestead

The official Laravel local development environment.

Official documentation [is located here](http://laravel.com/docs/homestead).

## Introduction
(from the official documentation)

Laravel strives to make the entire PHP development experience delightful, including your local development environment. Vagrant provides a simple, elegant way to manage and provision Virtual Machines.

Laravel Homestead is an official, pre-packaged Vagrant box that provides you a wonderful development environment without requiring you to install PHP, HHVM, a web server, and any other server software on your local machine. No more worrying about messing up your operating system! Vagrant boxes are completely disposable. If something goes wrong, you can destroy and re-create the box in minutes!

Homestead runs on any Windows, Mac, or Linux system, and includes the Nginx web server, PHP 7.0, MySQL, Postgres, Redis, Memcached, Node, and all of the other goodies you need to develop amazing Laravel applications.

## Why I did this fork
Using Laravel Homestead for my projects I had necessity to customize almost everything, I ended up touching up almost everything.

## What I did in this fork
 - Removed init.sh and init.bat, the script just copy some files into ~/.homestead, i don’t like it
 - Renamed Homestead.yaml into homestead.yml, less error prone for me, removed also the Homestead.json, i think yaml format is enough and better for these things because it supports comments
 - Refactored all the code using two design patterns,  a factory method(Homestead.create) that creates the Homestead object starting from settings or the settings filename and Homestead becomes a command, its execute method is still called configure but this time i’ve added two attributes to the object (settings and config), all parts of code that can be moved into a separate method are moved, so instead of a single method with ~250 lines i have ~400 lines of small methods. Also i’ve created custom getter/setter methods for settings in order to reduce the “||=” usage to set default values, the settings setter becomes a way to prevalidate all the settings
 - A new, smaller Vagrantfile, all the logic is moved into Homestead class, 8 lines of code into Vagrantfile, leaving Vagrant.configure inside Vagrantfile still allows more cutomizations directly there
 - At this point single methods can be overridden into a custom class but also I can specify directly what file and class will be called in the factory method, so i can override the standard homestead class adding 3 lines into homestead.yml
```yaml
override:
    file: ‘./config/customHomestead.rb’
    class: ‘CustomHomestead’
```
 - Disabled default port forwarding, if i want port forwarding i can still uncomment them in my homestead.yml
 - Moved after.sh into homestead.yml with two new lists called before_scripts and after_scripts
 - Created/edited separate install/remove scripts to install and remove some more things, mainly install apache and remove unnecessary server, with the right settings it’s possible to switch between nginx and apache just changing homestead.yml and running vagrant provision
 - Reduced noise on apt commands and added some more success and error messages
 - Improved site vhost management, adding mode: symlink and value: /home/vagrant/…/vhost_dev.conf vhost is just added via a symlink
 - Laravel site type now is called standard, because it is the standard php way:)
 - Added support of vagrant-hostmanager, vagrant-hostsupdater is still supported
 - Added some enable_* options to be able mainly to disable everything: enable_bindfs enable_clear_webserver enable_forward_agent enable_hostmanager enable_update_composer
 - Added also support for digitalocean, provisioning but still having some problems with the vagrant user, too tired atm:)

## Why I've not made a PR
I didn't because unfortunately at the moment many settings are no more backward compatible with the existing Laravel Homestead project.

## Install

### per project
composer require kernelfolla/homestead --dev
php vendor/bin/homestead make
vagrant up

### globally
git clone https://github.com/kernelfolla/homestead.git
cd homestead
vagrant up

## Changelog

### 1.0.1
 - minor fix
 - added new install options: yarn, prestissimo, mailhog
### 1.0.0
 - initial fork 
