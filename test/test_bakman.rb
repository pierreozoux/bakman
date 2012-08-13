require './lib/bakman.rb'
require 'test/unit'
require 'FileUtils'

class TestBackup < Test::Unit::TestCase
	def setup
		Dir.mkdir("test/temp_folder")
		Dir.chdir("test/temp_folder") 

		# During tests, we will
		# * delete a
		# *check that b is still there
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

		$a_backup_list = BackupList.new(Dir.pwd,$a_bck)
		$b_backup_list = BackupList.new(Dir.pwd,$b_bck)

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
	def test_Backup_delete
		$a_backups.each do |backup|
			temp_bck = Backup.new(backup[:path])
			temp_bck.delete!
			assert_equal false, File.exist?(backup[:path])
		end
		$b_backups.each do |backup|
			assert_equal true, File.exist?(backup[:path])
		end
	end

	def test_BackupList_initialize
		assert_equal false, $a_backup_list.empty?
		$a_backup_list.each_with_index do |a_temp_bck, i|
			assert_equal Date.today.prev_day($a_backups[i][:day]), a_temp_bck.date
		end
	end

	def test_BackupList_rotate!

		# Delete no backups when there are no backups in the time range
		$a_backup_list.rotate!(0, Date.today.prev_year(3), Date.today.prev_year(2))

		$a_backup_list.each do |a_temp_bck|
			assert_equal true, File.exist?(a_temp_bck.filepath)
		end

		# Keep exactly 3 backups in the time range between a month and a year ago
		# 4 backups : 100, 33, 32, 30
		$a_backup_list.rotate!(3, Date.today.prev_year, Date.today.prev_day(30))
		
		$a_backup_list.each do |a_temp_bck|
			if a_temp_bck.date == Date.today.prev_day(100)
				assert_equal false, File.exist?(a_temp_bck.filepath)
			else
				assert_equal true, File.exist?(a_temp_bck.filepath)
			end
		end

		# Keep exactly 2 backups in the time range between a week and a month ago
		# 3 backups : 9 8 7
		$a_backup_list.rotate!(2, Date.today.prev_day(29), Date.today.prev_day(7))

		$a_backup_list.each do |a_temp_bck|
			if a_temp_bck.date == Date.today.prev_day(100)
				assert_equal false, File.exist?(a_temp_bck.filepath)
			elsif a_temp_bck.date == Date.today.prev_day(9)
				assert_equal false, File.exist?(a_temp_bck.filepath)
			else
				assert_equal true, File.exist?(a_temp_bck.filepath)
			end
		end
		# Keep exactly 1 backup in the time range between today and a week ago
		# 3 backups : 6 2 0
		$a_backup_list.rotate!(1, Date.today.prev_day(6), Date.today)

		$a_backup_list.each do |a_temp_bck|
			if a_temp_bck.date == Date.today.prev_day(100)
				assert_equal false, File.exist?(a_temp_bck.filepath)
			elsif a_temp_bck.date == Date.today.prev_day(9)
				assert_equal false, File.exist?(a_temp_bck.filepath)
			elsif a_temp_bck.date == Date.today.prev_day(6) or a_temp_bck.date == Date.today.prev_day(2)
				assert_equal false, File.exist?(a_temp_bck.filepath)
			else
				assert_equal true, File.exist?(a_temp_bck.filepath)
			end
		end

		$b_backups.each do |backup|
			assert_equal true, File.exist?(backup[:path])
		end
	end

	def test_BackupList_rotate_gfs!
		$a_backup_list.rotate_gfs!(3,2,1)

		$a_backup_list.each do |a_temp_bck|
			if a_temp_bck.date == Date.today.prev_day(100)
				assert_equal false, File.exist?(a_temp_bck.filepath)
			elsif a_temp_bck.date == Date.today.prev_day(9)
				assert_equal false, File.exist?(a_temp_bck.filepath)
			elsif a_temp_bck.date == Date.today.prev_day(6) or a_temp_bck.date == Date.today.prev_day(2)
				assert_equal false, File.exist?(a_temp_bck.filepath)
			else
				assert_equal true, File.exist?(a_temp_bck.filepath)
			end
		end

		$b_backups.each do |backup|
			assert_equal true, File.exist?(backup[:path])
		end
	end
end
