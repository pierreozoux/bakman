# This classe require date to manipulate backup date and compare age between backups
require 'date'

# This class handles a collection of #Backup for the same object "something".
# This is useful to manipulate backups as a whole
class BackupList < Array

  # The object you want to manage the backups has 
  # * a #name
  # * the backups are saved in a #folder
  attr_reader :name, :folder, :lenght

  # This is populating the array with #Backup objects
  # It is sorted at the end for later manipulation on a date sorted array.
  def create(folder,name)
  	@name = name
  	@folder = folder
    @lenght = 0
    list = Dir.glob("#{folder}/#{name}*")
  	list.each do |path|
  	  self << Backup.new(path)
      @lenght += 1
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

  # A method to determine if a backup has to be kept or not.
  # We go thru the array in the reverse order. It allows to test the more recent entries first and keep them first.
  # To be kept, a backup needs :
  # * to have his ( #Backup.date ) between #down_date and #up_date
  # * to be more recent
  # * to not be already kept
  # It returns nb_kept for post analyses
  def keep_backup(nb_to_keep,down_date, up_date)
    range = down_date..up_date
    nb_kept = 0
    self.reverse_each do |bck|
      if range === bck.date
        if nb_kept < nb_to_keep
          if bck.to_keep != true
            puts "#{bck.filepath} will be kept!"
            bck.to_keep = true
            nb_kept += 1
          end
        end
      end
    end
    return nb_kept
  end

  # A useful method to rotate the files
  # * #nb_to_keep is the number of backups to keep betwwen the two #down_date and #up_date
  # (number above #number_to_keep will be deleted)
  def rotate(nb_to_keep, down_date, up_date)
    nb_kept = keep_backup(nb_to_keep,down_date, up_date)

    if nb_kept == nb_to_keep
      puts "There is enough backups for this time period."
    else
      puts "Not enough backups between #{down_date} and #{up_date}." 
      if up_date == Date.today
        puts "Instead of #{nb_to_keep} backup(s), you will have #{nb_kept} backup(s)"
      else
         puts "We will look for a closer period to find backups if possible."
         self.reverse.rotate(nb_to_keep - nb_kept, up_date, Date.today)
      end
    end
  end

    # a redefinition of the reverse method from the parent class array
    def reverse
      reversed = BackupList.new
      self.reverse_each do |bck|
        reversed << bck
      end
      return reversed
    end


  # A quick method to clean backups files, the one that are not to be kept ( Backup.to_keep == false )
  def clean_bck!
    self.each do |bck|
      if bck.to_keep == false
        bck.delete!
      end
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
    self.rotate(nb_g,Date.today.prev_year, Date.today.prev_day(30))

    puts "Rotate Father"
    self.rotate(nb_f,Date.today.prev_day(29), Date.today.prev_day(7))

    puts "Rotate Son"
    self.rotate(nb_s,Date.today.prev_day(6),Date.today)

    puts "Remove unecessary backups"
    self.clean_bck!

  end

  # A method to rsync the backup folder with a remote host describe by #host
  # #host should be username@machine
  # the ssh_keys have to be exchanged before using this (if not, it will failed)
  # /!\ the folder has to exist on the remote host.
  def rsync!(host, remote_folder)
  	puts "rsync #{folder}/#{name}* #{host}:#{remote_folder}"
  	`rsync --delete #{folder}/#{name}* #{host}:#{remote_folder}`
  end
end