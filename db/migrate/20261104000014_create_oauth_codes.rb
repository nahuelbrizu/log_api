class CreateOauthCodes < ActiveRecord::Migration[7.0]
  # One-time codes handed to the frontend at the end of a social login and
  # exchanged (with the PKCE verifier) for tokens. Stored as digests.
  def change
    create_table :oauth_codes do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :code_digest, null: false, limit: 64
      t.string :code_challenge, null: false, limit: 128
      t.string :redirect_uri, null: false, limit: 2000
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.timestamps
    end
    add_index :oauth_codes, :code_digest, unique: true
    add_index :oauth_codes, :expires_at
  end
end
