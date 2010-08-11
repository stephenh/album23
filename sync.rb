#!/usr/bin/ruby

require 'rubygems'
require 'flickraw'
require 'sqlite3'

module FlickRaw
  FLICKR_HOST = 'www.23hq.com'
end

email = ARGV[0]
password = ARGV[1]
user_id = flickr.test.login(:email => email, :password => password)['id']

should_create = ! File.exists?('sync.db')
db = SQLite3::Database.new('sync.db')

if should_create then
  db.execute_batch <<SQL
    CREATE TABLE photos (
      id int,
      date_taken varchar(50),
      path varchar(200)
   );
SQL
end

page = 1
while true do
  puts "page #{page}"
  photos = flickr.photos.search(
                                :user_id => user_id,
                                :extras => 'date_taken',
                                :per_page => 500,
                                :page => page,
                                :email => email,
                                :password => password
                               )
  photos.each do |photo|
    count = db.get_first_value('SELECT count(*) FROM photos WHERE id = ?', photo['id'])
    if count == '0' then
      db.execute(
                'INSERT INTO photos (id, date_taken, path) VALUES (?, ?, null);',
                photo['id'],
                photo['datetaken']
                )
    end
  end
  if photos.size == 500
    page = page + 1
  else
    break
  end
end


