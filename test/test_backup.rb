require './lib/bakman/backup'
require 'test/unit'
require 'FileUtils'

class TestBackup < Test::Unit::TestCase
	def setup
		Dir.mkdir("test/temp_folder")
		Dir.chdir("test/temp_folder")

		# During tests, we will
		# * delete a
		# * check that b is still there
		$a_bck = "msl"
		$b_bck = "voyager"

		def create_backups(name)
		  days = [100,33,32,30,9,8,7,6,2,0]
		  backups = []
			days.each do |day|
				path = Date.today.prev_day(day).strftime("#{name}_%Y%m%dT%H%M_#{day}")
				backups << {day: day, path: path}
				File.new(path, "w+")
			end
			return backups
		end
		
		$a_backups = create_backups($a_bck)
		$b_backups = create_backups($b_bck)
		
		end

	def teardown
		Dir.chdir("../..")
		FileUtils.rm_rf(Dir["test/temp_folder"])
	end

	def test_Backup_initialize

		$a_backups.each do |backup|
			assert_equal Date.today.prev_day(backup[:day]), Backup.new(backup[:path]).date
		end

		#Test on different folder names
		assert_equal Date.new(2012,4,20), Backup.new("~/random_folder_after_home/backup_name_20120420T1023").date
		assert_equal Date.new(2012,4,19), Backup.new("/tmp/random_folder_after/backup_name_20120419T1023").date
		assert_equal Date.new(2012,10,4), Backup.new("../random_relative_folder/backup_name_20121004T1023").date
	end
	
	def test_Backup_delete!
		$a_backups.each do |backup|
			temp_bck = Backup.new(backup[:path])
			temp_bck.delete!
			assert_equal false, File.exist?(backup[:path])
		end
		$b_backups.each do |backup|
			assert_equal true, File.exist?(backup[:path])
		end
	end
end