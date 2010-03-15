class Recipe < ActiveRecord::Base
  has_many :recipe_ingredients
  has_many :ingredients, :through => :recipe_ingredients
  has_many :recipe_ratings
  has_many :recipe_comments
  has_many :recipe_instructions

  define_index do
    indexes title, :sortable => true
 #   indexes recipe.ingredients.name, :as => :ingredient, :sortable => true
    has prep_time  
  end
  
end
