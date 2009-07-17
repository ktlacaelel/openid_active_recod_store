# Uninstall hook code here

require 'ftools'

# keep everything inside fo this scope
class UnInstallOpenIdActiveRecordStore

  def initialize
    show_banner
    check_system_cosistency
    remove_migration_files
  end

  def here
    File.dirname(__FILE__)
  end

  def sources
    Dir.glob(File.join([here, 'migrations', '*.*']))
  end

  def migrations_files
    Dir.glob(File.join([target, '*.*']))
  end

  def validate_file_existance(file)
    abort "File not found: #{target}" unless File.exist? file
  end

  def show_banner
    puts '
      ** Deleting migrations to your application
    '
  end

  def check_system_cosistency
    validate_file_existance(target)
    sources.each { |file| validate_file_existance(file) }
  end

  def remove_migration_files
    migrations_files.each do |file|
      puts 'Will delete ' + file
      validate_file_existance(file)
      File.rm_f file
    end
  end

  def target
    File.join([here, '..', '..', '..', 'db', 'migrate'])
  end

end

UnInstallOpenIdActiveRecordStore.new
