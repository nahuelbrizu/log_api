class CreateJwtDenylists < ActiveRecord::Migration[7.0]
  # Revoked access tokens (by jti) until they expire. See JwtDenylist.
  def change
    create_table :jwt_denylists do |t|
      t.string :jti, null: false
      t.datetime :exp, null: false
      t.timestamps
    end
    add_index :jwt_denylists, :jti, unique: true
    add_index :jwt_denylists, :exp
  end
end
