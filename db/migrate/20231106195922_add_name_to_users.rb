class AddNameToUsers < ActiveRecord::Migration[7.0]
  def change
    change_table :users do |t|
      t.column :name, :string, :default => "None"
    end
  end
end
