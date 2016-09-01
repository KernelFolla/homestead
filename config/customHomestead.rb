class CustomHomestead < Homestead
  def configure(config)
    puts 'Running CustomHomestead'
    super
  end
end
