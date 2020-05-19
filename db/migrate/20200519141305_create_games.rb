class CreateGames < ActiveRecord::Migration[6.0]
  def change
    create_table :games do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :archived, null: false, default: false

      t.timestamps
    end
  end
end
