class CreateRefreshTokens < ActiveRecord::Migration[7.0]
  # Long-lived refresh tokens, stored as SHA-256 digests. Tokens rotated
  # from the same login share a family_id, so reuse of a rotated token can
  # revoke the whole chain.
  def change
    create_table :refresh_tokens do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :token_digest, null: false, limit: 64
      t.string :family_id, null: false, limit: 36
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.string :user_agent
      t.string :ip_address, limit: 45
      t.timestamps
    end
    add_index :refresh_tokens, :token_digest, unique: true
    add_index :refresh_tokens, :family_id
    add_index :refresh_tokens, :expires_at
  end
end
