require './lib/bakman/backuplist'
require 'test/unit'
require 'FileUtils'

class TestBackup < Test::Unit::TestCase
	

	def create_backups(name, days)
	  backups = []
		days.each do |day|
			path = Date.today.prev_day(day).strftime("#{name}_%Y%m%dT%H%M_#{day}")
			backups << {day: day, path: path}
			File.new(path, "w+")
		end
		return backups
	end

	def setup
		Dir.mkdir("test/temp_folder")
		Dir.chdir("test/temp_folder") 

		# During tests, we will
		# * delete a
		# *check that b is still there
		$a_bck = "msl"
		$b_bck = "voyager"

		days = [100,33,32,30,9,8,7,6,2,0]
		
		$a_backups = create_backups($a_bck, days)
		$b_backups = create_backups($b_bck, days)


		$a_backup_list = BackupList.new
		$b_backup_list = BackupList.new

		$a_backup_list.create(Dir.pwd,$a_bck)
		$b_backup_list.create(Dir.pwd,$b_bck)


	end

	def teardown
		Dir.chdir("../..")
		FileUtils.rm_rf(Dir["test/temp_folder"])
	end

	def test_BackupList_initialize
		assert_equal false, $a_backup_list.empty?
		$a_backup_list.each_with_index do |a_temp_bck, i|
			assert_equal Date.today.prev_day($a_backups[i][:day]), a_temp_bck.date
		end
	end

	# a little function which return the backup from a given day
	def day_bck(day,bcklist)
		bcklist.each do |bck|
			if bck.date == Date.today.prev_day(day)
				return bck
			end
		end
	end

	def matrix_test(matrix,bcklist,&block)
		matrix.each do |test|
			day = test[0]
			expected_result = test[1]

			block.call(expected_result, day_bck(day,bcklist))
		end
	end

	def test_BackupList_keep_backup

		# Keep no backups when there are no backups to keep
		nb_kept = $a_backup_list.keep_backup(0, Date.today.prev_year(3), Date.today.prev_year(2))

		assert_equal 0, nb_kept

		$a_backup_list.each do |a_temp_bck|
			assert_equal false, a_temp_bck.to_keep
		end

		# Keep exactly 3 backups in the time range between a month and a year ago
		# 4 backups : 100, 33, 32, 30

		#expected matrix :
		expected_matrix = [ [100,false],[33,true],[32,true],[30,true],
											[9,false],  [8,false],[7,false],[6,false],
											[2,false],[0,false]
										]
		
		nb_kept = $a_backup_list.keep_backup(3, Date.today.prev_year, Date.today.prev_day(30))
		
		assert_equal 3, nb_kept

		matrix_test(expected_matrix,$a_backup_list) do |expected_result, bck|
			assert_equal expected_result, bck.to_keep
		end

		# Keep exactly 2 backups in the time range between a week and a month ago
		# 3 backups : 9 8 7

		#expected matrix :
		expected_matrix = [ [100,false],[33,true],[32,true],[30,true],
											[9,false],  [8,true],[7,true],[6,false],
											[2,false],[0,false]
										]

		nb_kept = $a_backup_list.keep_backup(2, Date.today.prev_day(29), Date.today.prev_day(7))

		assert_equal 2, nb_kept
		
		matrix_test(expected_matrix,$a_backup_list) do |expected_result, bck|
			assert_equal expected_result, bck.to_keep
		end

		# Keep exactly 1 backup in the time range between today and a week ago
		# 3 backups : 6 2 0

		#expected matrix :
		expected_matrix = [ [100,false],[33,true],[32,true],[30,true],
											[9,false],  [8,true],[7,true],[6,false],
											[2,false],[0,true]
										]

		nb_kept = $a_backup_list.keep_backup(1, Date.today.prev_day(6), Date.today)

		assert_equal 1, nb_kept
		
		matrix_test(expected_matrix,$a_backup_list) do |expected_result, bck|
			assert_equal expected_result, bck.to_keep
		end

		# Redo the same to test that nb_kept will be 1 and 100 will become true.

		#expected matrix :
		expected_matrix = [ [100,true],[33,true],[32,true],[30,true],
											[9,false],  [8,true],[7,true],[6,false],
											[2,false],[0,true]
										]
		
		nb_kept = $a_backup_list.keep_backup(3, Date.today.prev_year, Date.today.prev_day(30))
		
		assert_equal 1, nb_kept

		matrix_test(expected_matrix,$a_backup_list) do |expected_result, bck|
			assert_equal expected_result, bck.to_keep
		end

		# Redo the same to test that nb_kept will be 0.

		#expected matrix :
		expected_matrix = [ [100,true],[33,true],[32,true],[30,true],
											[9,false],  [8,true],[7,true],[6,false],
											[2,false],[0,true]
										]
		
		nb_kept = $a_backup_list.keep_backup(3, Date.today.prev_year, Date.today.prev_day(30))
		
		assert_equal 0, nb_kept

		matrix_test(expected_matrix,$a_backup_list) do |expected_result, bck|
			assert_equal expected_result, bck.to_keep
		end

		# at the beginning, should be all false

		$b_backup_list.each do |backup|
			assert_equal false, backup.to_keep
		end

	end

	def test_BackupList_clean_bck
		# expected matrix :
		expected_matrix = [ [100,true],[33,true],[32,true],[30,true],
											[9,false],  [8,true],[7,true],[6,false],
											[2,false],[0,true]
										]

		# Fill the BackupList
		matrix_test(expected_matrix,$a_backup_list) do |expected_result,bck|
			bck.to_keep = expected_result
		end

		# clean!
		$a_backup_list.clean_bck!

		# Test the expected behavior
		matrix_test(expected_matrix,$a_backup_list) do |expected_result,bck|
			assert_equal expected_result, File.exist?(bck.filepath)
		end

		# Test it will not delete other backps
		matrix_test(expected_matrix,$b_backup_list) do |expected_result,bck|
			assert_equal true, File.exist?(bck.filepath)
		end

	end

	def test_BackupList_reverse
		#Test normal order
		$a_backup_list.each_with_index do |bck,index|
			if index < $a_backup_list.lenght - 1
				assert_operator($a_backup_list[index].date.to_time, :<, $a_backup_list[index+1].date.to_time )
			end
		end

		#Test reverse order
		assert_equal BackupList,$a_backup_list.reverse.class

		assert_equal false, $a_backup_list.reverse.empty?

		$a_backup_list.reverse.each_with_index do |bck,index|
			if index < $a_backup_list.lenght - 1
				assert_operator($a_backup_list.reverse[index].date.to_time, :>, $a_backup_list.reverse[index+1].date.to_time )
			end
		end
	end

	def test_BackupList_rotate
		# Keep exactly 3 backups in the time range between a month and a year ago
		# 4 backups : 100, 33, 32, 30

		#expected matrix :
		expected_matrix = [ [100,false],[33,true],[32,true],[30,true],
											[9,false],  [8,false],[7,false],[6,false],
											[2,false],[0,false]
										]
		
		$a_backup_list.rotate(3, Date.today.prev_year, Date.today.prev_day(30))
		
		matrix_test(expected_matrix,$a_backup_list) do |expected_result, bck|
			assert_equal expected_result, bck.to_keep
		end

		# Keep exactly 2 backups in the time range between a week and a month ago
		# 3 backups : 9 8 7

		#expected matrix :
		expected_matrix = [ [100,false],[33,true],[32,true],[30,true],
											[9,false],  [8,true],[7,true],[6,false],
											[2,false],[0,false]
										]

		$a_backup_list.rotate(2, Date.today.prev_day(29), Date.today.prev_day(7))

		matrix_test(expected_matrix,$a_backup_list) do |expected_result, bck|
			assert_equal expected_result, bck.to_keep
		end

		# at the beginning, should be all false

		$b_backup_list.each do |backup|
			assert_equal false, backup.to_keep
		end

		# Keep exactly 6 backups in the time range between a month and a year ago
		# 4 backups : 100, 33, 32, 30 in the time range
		# Should keep 2 more backups : 9 and 8

		#expected matrix :
		expected_matrix = [ [100,true],[33,true],[32,true],[30,true],
											[9,true],  [8,true],[7,false],[6,false],
											[2,false],[0,false]
										]
		
		$b_backup_list.rotate(6, Date.today.prev_year, Date.today.prev_day(30))
		
		matrix_test(expected_matrix,$b_backup_list) do |expected_result, bck|
			assert_equal expected_result, bck.to_keep
		end
		
		# Keep exactly 2 backups in the time range between a week and a month ago
		# 3 backups : 9 8 7

		#expected matrix :
		expected_matrix = [ [100,true],[33,true],[32,true],[30,true],
											[9,true],  [8,true],[7,true],[6,true],
											[2,false],[0,false]
										]

		$b_backup_list.rotate(2, Date.today.prev_day(29), Date.today.prev_day(7))

		matrix_test(expected_matrix,$b_backup_list) do |expected_result, bck|
			assert_equal expected_result, bck.to_keep
		end

	end

	def test_BackupList_rotate_gfs!
		#expected matrix :
		expected_matrix = [ [100,false],[33,true],[32,true],[30,true],
											[9,true],  [8,true],[7,true],[6,true],
											[2,false],[0,true]
										]
		
		$a_backup_list.rotate_gfs!(3,4,1)


		matrix_test(expected_matrix,$a_backup_list) do |expected_result, bck|
			assert_equal expected_result, File.exist?(bck.filepath)
		end

		$b_backups.each do |backup|
			assert_equal true, File.exist?(backup[:path])
		end
	end
end
