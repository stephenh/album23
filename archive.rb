
require 'rubygems'
require 'album'
require 'ftools'

i = 0

album = Album.new
destination = 'e:\haberman\pictures\20100725'

album.images.values.delete_if { |image| image.is_movie? }.sort.each do |image|
  if File.exists? image.path then
    puts "On #{i} #{image.path}"
    File.copy image.path, "#{destination}\\IMG_#{i.to_s.rjust(5, '0')}.jpg"
    i = i + 1
  end
end

