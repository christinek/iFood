class CreateUserIngredients < ActiveRecord::Migration
  def self.up
    create_table :user_ingredients do |t|
      t.integer :user_id
      t.integer :ingredient_id 
      t.float :qty 
      t.string :unit
      t.timestamps
      t.timestamps
    end
  end

  def self.down
    drop_table :user_ingredients
  end
end
