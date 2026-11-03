class MakeProfilesUserIdUnique < ActiveRecord::Migration[7.0]
  # A user has_one profile. The foreign key needs an index, so add the unique
  # one before dropping the plain one. Fails if duplicate profiles already
  # exist: clean them up first.
  def change
    add_index :profiles, :user_id, unique: true, name: "index_profiles_on_user_id_unique"
    remove_index :profiles, :user_id, name: "index_profiles_on_user_id"
    rename_index :profiles, "index_profiles_on_user_id_unique", "index_profiles_on_user_id"
  end
end
