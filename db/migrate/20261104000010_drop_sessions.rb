class DropSessions < ActiveRecord::Migration[7.0]
  # Server-side sessions are no longer used: auth is stateless (JWT) and the
  # OmniAuth handshake uses a short-lived encrypted cookie.
  def change
    drop_table :sessions do |t|
      t.string :session_id, null: false
      t.text :data
      t.timestamps
      t.index :session_id, unique: true
      t.index :updated_at
    end
  end
end
