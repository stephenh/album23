# = Album
#   An interface to the Adobe Album Access database.
#
# Author::    Stephen Haberman <stephenh@chase3000.com>
# Copyright:: Copyright (c) 2005 Stephen Haberman <stephenh@chase3000.com>
# License::   MIT <http://www.opensource.org/licenses/mit-license.php>
#

require 'dbi'
require 'date'

DEFAULT_PATH = 'Driver={Microsoft Access Driver (*.mdb)};Dbq=C:\Documents and Settings\All Users\Application Data\Adobe\Photoshop Album\Catalogs\My Catalog.psa'

# Reads in the images and tags from the Access db and converts them into a nice
# object graph.
class Album

  attr_accessor :images, :tags

  def initialize(path=DEFAULT_PATH)
    @images = {}
    @tags = {}

    DBI.connect "DBI:odbc:#{path}" do |dbh|
      dbh.select_all('select * from FolderTable') do |row|
        #puts "#{row['fFolderId']} -> #{row['fFolderId'].to_s(16)} -> #{row['fFolderName']}"
        @tags[row['fFolderId']] = Tag.new(self, row)
      end

      dbh.select_all 'select * from ImageTable' do |row|
        @images[row['fImageId']] = Image.new(self, row)
      end
    end
  end

end

class Tag
  attr_accessor :name, :note

  def initialize(album, row)
    @album = album
    @name = row['fFolderName']
    @note = row['fFolderNote']
  end

  def is_system_tag?
    !@note.nil? && @note.length > 0
  end

  def <=>(other)
    return @name <=> other.name
  end
end

class Image
  attr_accessor :id, :caption, :date, :tags

  def initialize(album, row)
    @album = album
    @id = row['fImageId']
    @path = row['fMediaFullPath'].strip
    @editedPath = row['fMediaEditedFullPath'].strip
    @caption = row['fImageCaption'].strip
    @date = row['fImageTime'].to_time

    array = row['fFolderInfoArray']
    codes = []
    (0..array.size-1).each do |i|
      if i % 8 == 0 then
        i0 = array[i+0..i+1].hex & 0xFF
        i1 = array[i+2..i+3].hex & 0xFF
        i2 = array[i+4..i+5].hex & 0xFF
        i3 = array[i+6..i+7].hex & 0xFF
        code = i0 | (i1 << 8) | (i2 << 16) | (i3 << 24)
        if code != 0 then
          codes << code
        end
      end
    end
    @tags = codes.map { |id| @album.tags[id] }.delete_if { |t| t.nil? || t.is_system_tag? || t.name.size == 0 }
  end

  def <=>(other)
    return @date <=> other.date
  end

  def path
    @editedPath.length > 0 ? @editedPath : @path
  end

  def is_movie?
    path.downcase.include? 'avi'
  end

end

