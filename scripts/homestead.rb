require 'yaml'

class Homestead
  def settings
    @settings
  end

  def settings=(s)
    #you can send an object or just an array
    if s.is_a? String
      s = Homestead.loadYamlFile(s)
    end

    #defining different directories in scripts_dirs you can override all shell scripts
    unless s.has_key? 'script_dirs'
      s['script_dirs'] = [File.expand_path('.', File.dirname(__FILE__))]
    end
    #these fields are array, you can remove to ignore
    %w(ports networks keys copy remove install databases folders sites before_scripts after_scripts variables).each do |key|
      unless s.has_key?(key) && s[key].respond_to?('each')
        s[key] = []
      end
    end

    #these fields are boolean, removed = false
    %w(enable_enable_bindfs enable_clear_webserver enable_forward_agent enable_hostmanager enable_hostmanager_ipresolver enable_update_composer enable_hostsupdater).each do |key|
      s[key] = s.has_key?(key) && s[key]
    end
    #some default values
    s['provider'] = s['provider'] ||= 'virtualbox'
    s['box'] = s['box'] ||= 'laravel/homestead'
    s['version'] = s['version'] ||= '>= 0.4.0'
    s['hostname'] = s['hostname'] ||= 'homestead-7'
    s['memory'] = '2048'
    s['cpus'] = '1'
    #ip just becomes a network
    if s['ip']
      s['networks'] = s['networks'] << {
          'type' => 'private_network',
          'ip' => s['ip']
      }
    end
    @settings = s
  end

  def self.create(settings)
    ret = self.new(settings)
    #writing override in your settings you can instantiate a different class
    if ret.settings.has_key?('override')
      unless ret.settings['override'].has_key?('file') && ret.settings['override'].has_key?('class')
        ret.fail_with_message('Please define file and class to override the standard Homestead class')
      end
      require File.expand_path(ret.settings['override']['file']);
      ret = Object.const_get(ret.settings['override']['class']).new(ret.settings)
    end

    ret
  end

  def self.loadYamlFile(fileName)
    unless File.file? fileName
      fail_with_message "File #{fileName} not found"
    end

    YAML::load(File.read(fileName))
  end

  def initialize(settings)
    self.settings = settings
  end

  def configure(config)
    @config = config
    # Set The VM Provider
    ENV['VAGRANT_DEFAULT_PROVIDER'] = @settings['provider']

    @settings['before_scripts'].each do |script|
      add_script(script)
    end

    config_box
    config_ssh

    if @settings['enable_hostmanager']
      config_hostmanager
    elsif @settings['enable_hostsupdater']
      config_hostsupdater
    end

    case settings['provider']
      when 'virtualbox'
        config_provider_virtualbox
      when 'vmware_fusion'
        config_provider_vmware
      when 'vmware_workstation'
        config_provider_vmware
      when 'parallels'
        config_provider_parallels
      when 'digital_ocean'
        config_provider_digitalocean
    end

    @settings['keys'].each do |key|
      add_ssh_key(key)
    end

    @settings['networks'].each do |network|
      add_network(network)
    end

    @settings['ports'].each do |port|
      add_forwarded_port(port)
    end

    @settings['copy'].each do |file|
      copy_file(file)
    end

    @settings['folders'].each do |folder|
      add_shared_folder(folder)
    end

    @settings['remove'].each do |name|
      @config.vm.provision 'shell' do |s|
        s.name = "Removing #{name}"
        s.path = get_script("remove-#{name}.sh")
      end
    end

    @settings['install'].each do |name|
      @config.vm.provision 'shell' do |s|
        s.name = "Installing #{name}"
        s.path = get_script("install-#{name}.sh")
      end
    end

    unless @settings['enable_clear_webserver']
      @config.vm.provision 'shell' do |s|
        s.path = get_script('clear-webserver.sh')
      end
    end

    @settings['sites'].each do |site|
      add_site(site)
    end

    @config.vm.provision 'shell' do |s|
      s.name = 'Restarting Webserver'
      s.path = get_script("restart-webserver.sh")
    end

    @settings['databases'].each do |db|
      add_database(db)
    end

    add_env_variables(settings['variables'], true)

    if @settings['enable_update_composer']
      update_composer
    end

    if @settings.has_key? 'blackfire'
      add_blackfire(@settings['blackfire'])
    end

    @settings['after_scripts'].each do |script|
      add_script(script)
    end
  end

  def config_hostmanager()
    unless Vagrant.has_plugin? 'vagrant-hostmanager'
      fail_with_message 'vagrant-hostmanager missing, please install the plugin with this command:\nvagrant plugin install vagrant-hostmanager'
    end
    @config.hostmanager.enabled = true
    @config.hostmanager.manage_host = true
    @config.hostmanager.manage_guest = true
    @config.hostmanager.aliases = @settings['sites'].map { |item| item['map'] }
    puts 'Hostmanager aliases: '+ @config.hostmanager.aliases.inspect
    if @settings['enable_hostmanager_ipresolver']
      config_hostmanager_ipresolver
    end
  end

  def config_hostmanager_ipresolver()
    if @settings['provider'] == 'virtualbox'
      #https://github.com/devopsgroup-io/vagrant-hostmanager/issues/86
      ret = ''
      @config.hostmanager.ip_resolver = proc do |vm, resolving_vm|
        if vm.id && Vagrant::Util::Platform.windows?
          ret = `\"#{ENV['VBOX_MSI_INSTALL_PATH']}\\VBoxManage\" guestproperty get #{vm.id} "/VirtualBox/GuestInfo/Net/1/V4/IP"`.split()[1]
        else
          ret = `VBoxManage guestproperty get #{vm.id} "/VirtualBox/GuestInfo/Net/1/V4/IP"`.split()[1]
          if ret == "value"
            puts "IMPORTANT: you need to run vagrant hostmanager separately because ip is not yet created"
            ret = nil
          end
        end
        puts "Box ip: #{ret}"
        ret
      end
    elsif @settings['provider'] == 'digital_ocean'
      ret = ''
      @config.hostmanager.ip_resolver = proc do |vm, resolving_vm|
        if hostname = (vm.ssh_info && vm.ssh_info[:host])
          vm.communicate.execute("hostname -I") do |type, contents|
            ret = contents.split("\n").first[/(\d+\.\d+\.\d+\.\d+)/, 1]
          end
        end
        puts "Box ip: #{ret}"
        ret
      end
    end
  end

  def config_hostsupdater()
    unless Vagrant.has_plugin? 'vagrant-hostsupdater'
      fail_with_message 'vagrant-hostsupdater missing, please install the plugin with this command:\nvagrant plugin install vagrant-hostsupdater'
    end
    @config.hostsupdater.aliases = @settings['sites'].map { |item| item['map'] }
    puts 'Hostsupdater aliases: '+ @config.hostsupdater.aliases.inspect
  end

  def config_box()
    @config.vm.box = @settings['box']
    @config.vm.box_version = @settings['version']
    @config.vm.hostname = @settings['hostname']
  end

  def add_network(network)
    if network['ip'] == 'dhcp'
      @config.vm.network 'private_network', type: "dhcp"
    else
    @config.vm.network network['type'], ip: network['ip'], bridge: network['bridge'] ||= nil
    end
  end

  def config_provider_virtualbox()
    # Configure A Few VirtualBox @settings
    @config.vm.provider 'virtualbox' do |vb|
      vb.name = @settings['name'] ||= 'homestead-7'
      vb.customize ['modifyvm', :id, '--memory', @settings['memory']]
      vb.customize ['modifyvm', :id, '--cpus', @settings['cpus']]
      vb.customize ['modifyvm', :id, '--natdnsproxy1', 'on']
      vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
      vb.customize ['modifyvm', :id, '--ostype', 'Ubuntu_64']
    end
  end

  def config_provider_vmware()
    # Configure A Few VMware @settings
    ['vmware_fusion', 'vmware_workstation'].each do |vmware|
      @config.vm.provider vmware do |v|
        v.vmx['displayName'] = @settings['name']
        v.vmx['memsize'] = @settings['memory']
        v.vmx['numvcpus'] = @settings['cpus']
        v.vmx['guestOS'] = 'ubuntu-64'
      end
    end
  end

  def config_provider_parallels()
    # Configure A Few Parallels @settings
    @config.vm.provider 'parallels' do |v|
      v.update_guest_tools = true
      v.memory = @settings['memory']
      v.cpus = @settings['cpus']
    end
  end

  def config_provider_digitalocean()
    unless Vagrant.has_plugin? 'vagrant-digitalocean'
      fail_with_message 'vagrant-digitalocean missing, please install the plugin with this command:\nvagrant plugin install vagrant-digitalocean, install also the box with vagrant box add digital_ocean https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box'
    end

    @config.vm.provider :digital_ocean do |provider, override|
      override.ssh.private_key_path = '~/.ssh/id_rsa'
      override.ssh.username = 'root'
      override.vm.box = 'digital_ocean'
      override.vm.box_url = "https://github.com/devopsgroup-io/vagrant-digitalocean/raw/master/box/digital_ocean.box"

      provider.token = @settings['digitalocean']['token'] ||= 'YOUR TOKEN'
      provider.image = @settings['digitalocean']['image'] ||= 'ubuntu-14-04-x64'
      provider.region = @settings['digitalocean']['region'] ||= 'nyc2'
      provider.size = @settings['digitalocean']['size'] ||= '512mb'
    end
  end

  def add_forwarded_port(port)
    @config.vm.network(
        'forwarded_port',
        guest: port['guest'] ||= port['send'],
        host: port['host'] ||= port['to'],
        protocol: port['protocol'] ||= 'tcp',
        auto_correct: true,
    )
  end

  def config_ssh()
    # Prevent TTY Errors
    @config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

    unless @settings['enable_forward_agent']
      # Allow SSH Agent Forward from The Box
      @config.ssh.forward_agent = true
    end

    # Configure The Public Key For SSH Access
    if @settings.include? 'authorize'
      if File.file? File.expand_path(@settings['authorize'])
        @config.vm.provision 'shell' do |s|
          s.name = "Authorizing #{@settings['authorize']}"
          s.inline = 'echo $1 | grep -xq "$1" /home/vagrant/.ssh/authorized_keys || echo "\n$1" | tee -a /home/vagrant/.ssh/authorized_keys'
          s.args = [File.read(File.expand_path(@settings['authorize']))]
        end
      end
    end
  end

  def add_ssh_key(key)
    @config.vm.provision 'shell' do |s|
      s.name = "Adding ssh key #{@key}"
      s.privileged = false
      s.inline = 'echo "$1" > /home/vagrant/.ssh/$2 && chmod 600 /home/vagrant/.ssh/$2'
      s.args = [File.read(File.expand_path(key)), key.split('/').last]
    end
  end

  def copy_file(file)
    @config.vm.provision 'file' do |f|
      f.source = File.expand_path(file['from'])
      f.destination = file['to'].chomp('/') + '/' + file['from'].split('/').last
    end
  end

  def add_shared_folder(folder)
    mount_opts = []

    if (folder['type'] == 'nfs')
      mount_opts = folder['mount_options'] ? folder['mount_options'] : ['actimeo=1', 'nolock']
    elsif (folder['type'] == 'smb')
      mount_opts = folder['mount_options'] ? folder['mount_options'] : ['vers=3.02', 'mfsymlinks']
    end

    # For b/w compatibility keep separate 'mount_opts', but merge with options
    options = (folder['options'] || {}).merge({mount_options: mount_opts})

    # Double-splat (**) operator only works with symbol keys, so convert
    options.keys.each { |k| options[k.to_sym] = options.delete(k) }

    @config.vm.synced_folder folder['map'], folder['to'], type: folder['type'] ||= nil, **options

    if @settings['enable_bindfs']
      unless Vagrant.has_plugin? 'vagrant-bindfs'
        fail_with_message 'vagrant-bindfs missing, please install the plugin with this command:\nvagrant plugin install vagrant-bindfs'
      end
      # Bindfs support to fix shared folder (NFS) permission issue on Mac
      if Vagrant.has_plugin?('vagrant-bindfs')
        @config.bindfs.bind_folder folder['to'], folder['to']
      end
    end
  end

  def add_site(site)
    type = guess_site_type(site)

    if type != 'disabled'
      @config.vm.provision 'shell' do |s|
        s.name = "Creating Site #{site['map']} as #{type}"
        s.path = get_script("serve-#{type}.sh")
        s.args = [
            site['map'],
            site['to'],
            site['port'] ||= '80',
            site['ssl'] ||= '443',
            site['mode'] ||= 'standard',
            site['value'] ||= ''
        ]
      end
    end

    # Configure The Cron Schedule
    if (site.has_key?('schedule'))
      @config.vm.provision 'shell' do |s|
        if (site['schedule'])
          s.name = "Creating Schedule #{site['to']}"
          s.path = get_script('cron-schedule.sh')
          s.args = [site['map'].tr('^A-Za-z0-9', ''), site['to']]
        else
          s.name = "Removing Schedules"
          s.inline = 'rm -f /etc/cron.d/$1'
          s.args = [site['map'].tr('^A-Za-z0-9', '')]
        end
      end
    end
  end

  def guess_site_type(site)

    if @settings.has_key?('install') && @settings['install'].include?('apache')
      return 'apache'
    end

    if site.has_key?('hhvm') && site['hhvm']
      return 'hhvm'
    end

    return site['type'] ||= 'standard'
  end

  def add_blackfire(settings)
    @config.vm.provision 'shell' do |s|
      s.name = "Adding Blackfire"
      s.path = get_script('blackfire.sh')
      s.args = [
          settings['id'],
          settings['token'],
          settings['client-id'],
          settings['client-token']
      ]
    end
  end

  def add_database(db)
    if db.is_a? String
      db = {'type' => 'mysql', 'name' => db}
    end

    unless db.has_key?('type')
      fail_with_message 'please define a type for database ' + db['name']
    end

    case db['type']
      when 'mysql'
        @config.vm.provision 'shell' do |s|
          s.name = "Creating MySQL Database #{db['name']}"
          s.path = get_script('create-mysql.sh')
          s.args = [db['name']]
        end
      when 'postgresql'
        @config.vm.provision 'shell' do |s|
          s.name = "Creating Postgres Database #{db['name']}"
          s.path = get_script('create-postgres.sh')
          s.args = [db['name']]
        end
      else
        fail_with_message "database type #{db['type']} not supported"
    end
  end

  def add_env_variables(variables, clear=true)
    if clear
      # Configure All Of The Server Environment Variables
      @config.vm.provision 'shell' do |s|
        s.name = 'Clear Variables'
        s.path = get_script('clear-variables.sh')
      end
    end

    variables.each do |var|
      @config.vm.provision 'shell' do |s|
        s.inline = 'echo "\nenv[$1] = \'$2\'" >> /etc/php/7.0/fpm/php-fpm.conf'
        s.args = [var['key'], var['value']]
      end

      @config.vm.provision 'shell' do |s|
        s.inline = 'echo "\n# Set Homestead Environment Variable\nexport $1=$2" >> /home/vagrant/.profile'
        s.args = [var['key'], var['value']]
      end
    end

    @config.vm.provision 'shell' do |s|
      s.inline = 'service php7.0-fpm restart'
    end
  end

  def update_composer()
    @config.vm.provision 'shell' do |s|
      s.name = 'Updating Composer'
      s.inline = '/usr/local/bin/composer self-update'
    end
  end

  def add_script(script)
    if script.is_a? String
      script = {'path' => script}
    end

    unless script.has_key? 'path'
      fail_with_message "please define path parameter in your script called #{script['name']}"
    end

    unless File.file? script['path']
      fail_with_message "file #{script['path']} not found"
    end

    @config.vm.provision 'shell' do |s|
      s.name = script['name'] ||= "Processing #{script["path"]}"
      s.path = script['path']
      s.privileged = script.has_key?('privileged') && script['privileged']
      if script.has_key?("args")
        s.args = script['args']
      end
    end
  end

  def get_script(name)
    @settings['script_dirs'].each do |dir|
      if File.file? "#{dir}/#{name}"
        return "#{dir}/#{name}"
      end
    end
    fail_with_message("script #{name} not found in folders #{@settings['script_dirs'].inspect}")
  end

  def fail_with_message(msg)
    fail Vagrant::Errors::VagrantError.new, msg
  end
end
