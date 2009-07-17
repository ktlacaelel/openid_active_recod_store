class CreateOpenidAssociations < ActiveRecord::Migration

  def self.up
    create_table :openid_associations do |t|

      # association fields
      t.datetime :issued
      t.integer :lifetime
      t.string :assoc_type
      t.text :handle
      t.text :secret

      # extra fields
      t.string :target, :size => 32 # store url as md5 for faster retrival
      t.text :server_url # store url

      t.timestamps
    end
  end

  def self.down
    drop_table :openid_associations
  end

end
