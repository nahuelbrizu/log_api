class AddConfirmableAndTrackableToUsers < ActiveRecord::Migration[7.0]
  def up
    change_table :users, bulk: true do |t|
      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip
    end
    add_index :users, :confirmation_token, unique: true

    # Users created before :confirmable existed must not get locked out.
    execute "UPDATE users SET confirmed_at = created_at WHERE confirmed_at IS NULL"
  end

  def down
    remove_index :users, :confirmation_token
    change_table :users, bulk: true do |t|
      t.remove :confirmation_token, :confirmed_at, :confirmation_sent_at, :unconfirmed_email,
               :sign_in_count, :current_sign_in_at, :last_sign_in_at,
               :current_sign_in_ip, :last_sign_in_ip
    end
  end
end
