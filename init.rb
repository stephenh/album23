# = Sync
#   Auto-upload your Adobe Album photos (with their tags) to 23 or Flickr.
#
# Author::    Stephen Haberman <stephenh@chase3000.com>
# Copyright:: Copyright (c) 2005 Stephen Haberman <stephenh@chase3000.com>
# License::   MIT <http://www.opensource.org/licenses/mit-license.php>
#

require 'rubygems'
require 'mini_exiftool'
require '23hq'
require 'album'
require 'active_record'

# Do some special requires and exit if being packagaed
if defined?(REQUIRE2LIB)
  require 'sqlite'
  require 'DBD/ODBC/ODBC.rb'
  exit
end

if $ARGV.length != 2
  # puts "Usage: album23.exe username password"
  # exit
end

# Silly hack to run outside of the exe
begin
  foo = oldlocation '.'
rescue
  def oldlocation path
    path
  end
end

album = Album.new

i = 0

album.images.values.delete_if { |image| image.is_movie? }.sort.each do |image|
  if File.exists? image.path and image.tags.size > 0 then
    puts "On #{i} #{image.path}"
    p = MiniExiftool.new image.path
    p["Subject"] = image.tags.map { |t| t.name }
    p.save
    i = i + 1
  end
end

exit


email = $ARGV[0]
password = $ARGV[1]

ActiveRecord::Base.colorize_logging = false
ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.logger.level = Logger::ERROR
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database  => "#{oldlocation('sync.db')}")
ActiveRecord::Migrator.migrate('schema')

class Flag < ActiveRecord::Base
end

exit

tt = TwentyThree.new
tt.login(email, password)
user = tt.users(email)

# Used to sort.reverse but now taking out reverse seems to get them upload in the order taken
album.images.values.delete_if { |image| image.is_movie? }.sort.each do |image|
  # Try our local cache first
  if Flag.find_by_path(image.path).nil?

    # Timing out
    # # Not found locally, do a search against 23 just to make sure our cache hasn't been clobbered
    # mysql_style_date = image.date.strftime('%Y-%m-%d %H:%M:%S')
    # puts "Checking if #{image.path} taken on #{mysql_style_date} is already uploaded"
    # photo = tt.photos({'max_taken_date' => mysql_style_date, 'min_taken_date' => mysql_style_date})[0]
    photo = nil

    if image.tags.length == 0
      puts "Skipping #{image.path}"
    elsif photo.nil?
      puts "Uploading #{image.path}"
      photo = tt.upload(
                image.path,
                '', # not supported, it seems
                image.caption,
                image.tags.collect { |t| t.name },
                is_public=1,
                is_friend=0,
                is_family=0)

      # Go ahead and update our local cache
      Flag.create :path => image.path, :photoId => photo.id
    end
  end
end

