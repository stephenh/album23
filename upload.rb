#!/usr/bin/ruby

require 'rubygems'
require 'flickraw.rb'
require 'sqlite3'
require 'rio'
require 'mini_exiftool'

module FlickRaw
  FLICKR_HOST = 'www.23hq.com'
end

email = ARGV[0]
password = ARGV[1]
user_id = flickr.test.login(:email => email, :password => password)['id']

db = SQLite3::Database.new('sync.db')

files = []
['2011'].each do |d|
  rio("/home/stephen/Pictures/#{d}").all.files.each do |file|
    files << file.path
  end
end

puts "Found #{files.length}"

files.sort.each do |path|
  is_modified = path.include? '(Modified)'
  has_modified = (!is_modified) && File.exists?(path.gsub('.', ' (Modified).'))
  if is_modified or !has_modified then
    exif = MiniExiftool.new path
    date_taken = exif['DateTimeOriginal'].strftime '%Y-%m-%d %H:%M:%S'
    tags = exif['Subject'].to_a.join ' '

    # Skip any photos without tags (pending review)
    if tags == '' then
      next
    end

    # Does our database think we've uploaded this before?
    count = db.get_first_value('SELECT count(*) FROM photos WHERE date_taken = ?', date_taken)
    if count > 0 then
      next
    end

    # Does 23hq think we've uploaded this before?
    photos = flickr.photos.search(
                                  :user_id => user_id,
                                  :email => email,
                                  :password => password,
                                  :max_taken_date => date_taken,
                                  :min_taken_date => date_taken
                                 )
    if photos.total > 0 then
      puts "Already uploaded #{path}"
      db.execute 'INSERT INTO photos (id, date_taken) VALUES (?, ?)', photos[0]['id'], date_taken
    else
      puts "Uploading #{path} #{tags}"
      p = flickr.upload_photo path, :tags => tags, :email => email, :password => password, :is_public => 1, :hidden => 2
      db.execute 'INSERT INTO photos (id, date_taken) VALUES (?, ?)', p, date_taken
    end
  end
end

