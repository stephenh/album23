
class Initial < ActiveRecord::Migration
  def self.up
    create_table :flags do |t|
      t.column :path, :string, :limit => 1000
      t.column :photoId, :string
    end
  end

  def self.down
    drop_table :flags
  end
end

