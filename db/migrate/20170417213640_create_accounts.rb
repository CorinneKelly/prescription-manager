class CreateAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts do |t|
      t.string :googleToken
      t.string :googleId
      t.string :name
      t.timestamps
    end
  end
end
