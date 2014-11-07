class CreateViolations < ActiveRecord::Migration
  def change
    # TODO: migrate these to migrations table
    rename_column :builds, :violations, :violations_archive

    create_table :violations do |t|
      t.timestamps null: false

      t.integer :build_id, null: false
      t.string :filename, null: false
      t.text :line, null: false, default: ""
      t.integer :line_number, null: false
      t.text :messages, array: true, default: [], null: false
    end

    add_index :violations, :build_id
  end
end
