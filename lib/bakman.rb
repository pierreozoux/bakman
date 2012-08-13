# This set of classes require date to manipulate backup date and compare age between backups
require 'date'

# This class represent one backup of "something"
class Backup

  # One backup refers to the #filepath that contains that backup.
  # That file has to be represented by #{name_of_something}_#{date}
  # The #date has to be represented this way : %Y%m%dT%H%M
  attr_reader :filepath, :date

  # create one instance of Backup with the #filepath
  def initialize(filepath)
  	@filepath = filepath
  	@date = Date.strptime(filepath[/\d{8}T\d{4}/],'%Y%m%dT%H%M')
  end

  # delete that backup (you could need that if the backup is too old)
  def delete!
  	puts "#{filepath} deleted."
    File.delete(filepath)
  	end
end


# This class handles a collection of #Backup for the same object "something".
# This is useful to manipulate backups as a whole
class BackupList < Array

  # The object you want to manage the backups has 
  # * a #name
  # * the backups are saved in a #folder
  attr_reader :name, :folder

  # This is populating the array with #Backup objects
  # It is sorted at the end for later manipulation on a date sorted array.
  def initialize(folder,name)
  	@name = name
  	@folder = folder
    list = Dir.glob("#{folder}/#{name}*")
  	list.each do |path|
  	  self << Backup.new(path)
  	end
  	self.sort_by! {|bck| bck.date}
  end

  # A short method to print the list of backups
  def list
  	puts "The list of backups for #{self.name}"
  	self.each do |bck|
  	  puts bck.filepath
  	end
  end

  # A useful method to rotate the files
  # * #nb_to_keep is the number of backups to keep betwwen the two #down_date and #up_date
  # (number above #number_to_keep will be deleted)
  def rotate!(nb_to_keep, down_date, up_date)
  	range = down_date..up_date
    list = []
  	self.each do |bck|
  		list << bck if range === bck.date
  	end

    if list.length == 0
      puts "No backup between #{down_date} and #{up_date}."
    elsif list.length <= nb_to_keep
      puts "There is no need to delete backups."
    else
      nb_to_delete = list.length - nb_to_keep
      puts "#{nb_to_keep} backup(s) will be kept and #{nb_to_delete} backup(s) will be deleted."
      list.pop(nb_to_keep)
      list.each {|bck| bck.delete!}
    end
  end

  # A method to do an automatic GrandFather Father Son rotation of the backups
  # Here a month is 30 days
  # * #nb_g is the number of GrandFather backups to keep (Monthly)
  # * #nb_f is the number of Father backups to keep (weekly)
  # * #nb_s is the number of son backups to keep (daily)
  #/!\ It checks until the prev year but not before.
  def rotate_gfs!(nb_g, nb_f, nb_s)

    puts "Rotate GrandFather"
    self.rotate!(nb_g,Date.today.prev_year, Date.today.prev_day(30))

    puts "Rotate Father"
    self.rotate!(nb_f,Date.today.prev_day(29), Date.today.prev_day(7))

    puts "Rotate Son"
    self.rotate!(nb_s,Date.today.prev_day(6),Date.today)

  end
  # A method to rsync the backup folder with a remote host describe by #host
  # #host should be username@machine
  # the ssh_keys have to be exchanged before using this (if not, it will failed)
  # /!\ the folder has to exist on the remote host.
  def rsync!(host, remote_folder)
  	puts "rsync #{folder}/#{name}* #{host}:#{remote_folder}"
  	`rsync #{folder}/#{name}* #{host}:#{remote_folder}`
  end
end