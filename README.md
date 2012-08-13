bakman
=================

A sinmple way to manage your backup files.

### Usage

Put this in your script (backup.rb)

	require 'bakman'

	backups = BackupList.new("/path/to/your/folder", "name_of_your_backup")
	# Keep 1 backup for the last 4 years
	backups.rotate!(2, Date.today.prev_year(4), Date.today.prev_year(1))
	# Keep them in the GrandFather Father Son way (1 GF, 2 F, 3 S)
	backups.rotate_gfs!(1,2,3)
	# sync your backups
	backups.rsync!("user@host", "/path/to/your/remote/folder")

And enjoy it!
	
	$ gem install bakman
	$ ruby backup.rb
	
	2 backup(s) will be kept and 1 backup(s) will be deleted.
	/path/to/your/folder/name_of_your_backup_20120810T0001 deleted.
	...
	rsync /path/to/your/folder user@host:/path/to/your/remote/folder
	...

Requirements
------------

### Name convention
	
The filename of your backups should have the following "regex" pattern

	.*?[YYYYmmddTHHMM].*

### Rsync

 - The remote folder has to be created.
 - You have to exchange SSH keys between your computer and the remote host. Here is a quick tutorial for that : http://oreilly.com/pub/h/66