Gem::Specification.new do |s|
  s.name        = 'bakman'
  s.version     = '1.0.0'
  s.date        = '2012-08-10'
  s.summary     = "A sinmple way to manage your backup files."
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
