class CreateSamples < ActiveRecord::Migration[6.1]
  def change
    create_table :samples do |t|
      t.text :description

      t.timestamps
    end
  end
end
