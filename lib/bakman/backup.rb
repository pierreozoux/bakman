# This classe require date to manipulate backup date and compare age between backups
require 'date'


# This class represent one backup of "something"
class Backup

  # One backup refers to the #filepath that contains that backup.
  # That file has to be represented by #{name_of_something}_#{date}
  # The #date has to be represented this way : %Y%m%dT%H%M
  attr_reader :filepath, :date
  attr_accessor :to_keep

  # create one instance of Backup with the #filepath
  def initialize(filepath)
  	@filepath = filepath
  	@date = Date.strptime(filepath[/\d{8}T\d{4}/],'%Y%m%dT%H%M')
    @to_keep = false
  end

  # delete that backup (you could need that if the backup is too old)
  def delete!
    puts "#{filepath} deleted."
    File.delete(filepath)
  end
end