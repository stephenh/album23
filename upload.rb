#!/usr/bin/ruby

# uploads any tagged photo

require 'rubygems'
require 'flickraw'
require 'sqlite3'
require 'rio'
require 'mini_exiftool'
require_relative 'token'

user_id = flickr.test.login['id']

db = SQLite3::Database.new('sync.db')

files = []
['2015'].each do |d|
  rio("/home/stephen/Pictures/#{d}").all.files.each do |file|
    files << file.path
  end
end

puts "Found #{files.length}"

files.sort.reverse.each do |path|
  is_modified = path.include? '(Modified)'
  has_modified = (!is_modified) && File.exists?(path.gsub('.', ' (Modified).'))
  if is_modified or !has_modified then
    exif = MiniExiftool.new path
    date_taken_time = exif['DateTimeOriginal']
    date_taken = date_taken_time.strftime '%Y-%m-%d %H:%M:%S'
    tags = exif['Subject'].is_a?(String) ? exif['Subject'] : exif['Subject'].to_a.join(' ')
    title = exif['Title'] # if nil, just ignored

    # Skip any photos without tags (pending review)
    if tags == '' then
      puts "No tags on #{path}"
      next
    end

    # Does our database think we've uploaded this before?
    count = db.get_first_value('SELECT count(*) FROM photos WHERE date_taken = ?', date_taken)
    if count > 0 then
      next
    end

    # Does 23hq think we've uploaded this before?
    photos = flickr.photos.search(:user_id => user_id, :max_taken_date => date_taken, :min_taken_date => date_taken)
    if photos.total.to_i > 0 then
      puts "Already uploaded #{path}"
      db.execute 'INSERT INTO photos (id, date_taken) VALUES (?, ?)', photos[0]['id'], date_taken
    else
      puts "Uploading #{path} #{tags}"
      is_public = if tags.include?("private") or tags.include?("papa") or tags.include?("judy") then 0 else 1 end
      photo_id = flickr.upload_photo path, :title => title, :tags => tags, :is_public => is_public, :hidden => 2
      # fix sorting order by setting date posted == date taken
      flickr.photos.setDates(:photo_id => photo_id, :date_posted => date_taken_time.to_i)
      db.execute 'INSERT INTO photos (id, date_taken) VALUES (?, ?)', photo_id, date_taken
    end
  end
end

