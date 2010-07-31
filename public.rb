# = Public
#   Utility script to make all of your 23hq pictures public.
#
# Author::    Stephen Haberman <stephenh@chase3000.com>
# Copyright:: Copyright (c) 2005 Stephen Haberman <stephenh@chase3000.com>
# License::   MIT <http://www.opensource.org/licenses/mit-license.php>
#

require '23hq'
require 'pp'

if $ARGV.length != 2
  puts "Usage: sync.rb username password"
  exit
end

email = $ARGV[0]
password = $ARGV[1]

tt = TwentyThree.new
tt.login(username, password)
user = tt.users(username)

page = 1

while page > 0
  photos = tt.photos({'user_id' => user.id, 'per_page' => '100', 'page' => "#{page}"})

  puts "Doing a batch of #{photos.length}"

  photos.each { |p| p.set_perms(is_public=1, is_family=0, is_friend=0, perm_comment=3, perm_addmeta=1) }

  if photos.length == 100
    page = page + 1
  else
    page = -1
  end
end


