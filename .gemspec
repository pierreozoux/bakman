Gem::Specification.new do |s|
  s.name        = 'bakman'
  s.version     = '1.0.1'
  s.date        = '2012-09-11'
  s.summary     = "A simple way to manage your backup files."
  s.description = "It is for writing scripts for UNIX-like systems to handle your backups in a quick way."
  s.authors     = ["Pierre Ozoux"]
  s.email       = 'pierre.ozoux@gmail.com'
  s.files       = [
    "lib/bakman.rb",
    "lib/bakman/backup.rb",
    "lib/bakman/backuplist.rb",
  ]
  s.homepage    =
    'http://rubygems.org/gems/bakman'
end
