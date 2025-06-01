class CreateAttendances < ActiveRecord::Migration[7.1]
  def change
    create_table :attendances do |t|
      t.string :status
      t.date :date
      t.time :time
      t.references :profile, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.references :branch, null: false, foreign_key: true

      t.timestamps
    end
  end
end
