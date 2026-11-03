class RemoveRememberableFromUsers < ActiveRecord::Migration[7.0]
  # Devise :rememberable is a cookie feature; refresh tokens replace it.
  def change
    remove_column :users, :remember_created_at, :datetime
    change_column_default :users, :name, from: "None", to: nil
  end
end
