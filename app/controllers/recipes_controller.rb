class RecipesController < ApplicationController
  before_filter :login_required, :except => [:show, :index_all]
  def new
    @recipe = Recipe.new
    @recipe_instruction = @recipe.recipe_instructions.new()
    @recipe_ingredient = @recipe.recipe_ingredients.new()
  end

  def edit
    @recipe = Recipe.find(params[:id])
    @recipe_instruction = @recipe.recipe_instructions.find(:all, :conditions => {:recipe_id => params[:id]})
    @recipe_ingredient = @recipe.recipe_ingredients.find(:all, :conditions => {:recipe_id => params[:id]})
  end
  
  def update
    @recipe = Recipe.find(params[:id])

    params[:recipe_ingredients_update].each { |key, value| RecipeIngredient.find( key ).update_attributes(value)}
    params[:recipe_instructions_update].each { |key, value| RecipeInstruction.find( key ).update_attributes(value) }
    params[:recipe_ingredient].each { |p| @recipe.recipe_ingredients << RecipeIngredient.new( p ) } if params[:recipe_ingredient]
  	params[:recipe_instruction].each { |p| @recipe.recipe_instructions << RecipeInstruction.new( p ) } if params[:recipe_instruction]
  	
  	if @recipe.update_attributes(params[:recipe])
  	  redirect_to :action => 'show', :id => @recipe.id
	  else
      @recipe_instruction = @recipe.recipe_instructions.new()
	    render :action => 'new'
	  end
  end
  
  def add_instruction
    @recipe_instruction = RecipeInstruction.new()
  end
  
  def add_ingredient
    @recipe_ingredient = RecipeIngredient.new()
  end

  def approve
    @recipe = Recipe.find(params[:id])
    @recipe.update_attribute(:approved, true)
    flash[:notice] = "Recipe Successfully Approved"
    redirect_to :action => 'show', :id => @recipe.id
  end
  
  def destroy
    @recipe = Recipe.find(params[:id])
    @recipe.destroy
    flash[:notice] = "Successfully Deleted Recipe"
    redirect_to :controller => 'admin', :action => 'index'
  end
  
  def create
    @recipe = Recipe.new(params[:recipe])
    
  	params[:recipe_ingredient].each { |p| @recipe.recipe_ingredients << RecipeIngredient.new( p ) }
  	params[:recipe_instruction].each { |p| @recipe.recipe_instructions << RecipeInstruction.new( p ) }
  	
  	if @recipe.save
  	  admin = User.find_by_is_admin(true)
  	  UserMailer.deliver_new_recipe(admin, @recipe)
  	  redirect_to :action => 'show', :id => @recipe.id
	  else
      @recipe_instruction = @recipe.recipe_instructions.new()
	    render :action => 'new'
	  end
  end
  
  def show
    
    @recipe = Recipe.find(params[:id])
    @recipe_comments = @recipe.recipe_comments
    @recipe_ratings = @recipe.recipe_ratings
    @recipe_avg_rating = avg_rating()
    if @serving_qty.nil?
      @serving_qty = @recipe.serving_qty
    end
    rid = params[:id].to_i
    if session[:recentlyViewed].kind_of? Array
        # if the array has this rid already, remove it so this is more recent
        if session[:recentlyViewed].include?( rid )
           session[:recentlyViewed].delete( rid )  
        end
        session[:recentlyViewed] << rid
    else
        session[:recentlyViewed] = Array.new()
        session[:recentlyViewed] << rid
    end 

  end

  def index_all
  end

  def avg_rating
    ratings = RecipeRating.all(:conditions => ["recipe_id =?", params[:id]], :select => "rating")
    rating_sum = 0
    for r in ratings
        rating_sum = rating_sum + r.rating
    end

    res = 0
    if ratings.size != 0
        res = rating_sum / ratings.size
    end
    return res
  end

  def rate
    r = RecipeRating.all(:conditions => ["recipe_id = ? AND user_id = ?", params[:id], current_user.id])
    msg = "Your rating has been saved."
    if r.size != 0 
        @recipe_ratings = RecipeRating.update( r.first.id, :rating => params[:rate][:rating].to_i )
        msg = "Your rating has been updated."
    else
         @recipe_ratings = RecipeRating.new(:recipe_id => params[:id], :user_id => current_user.id, :rating => params[:rate][:rating].to_i )
    end
    if @recipe_ratings.save
      flash[:notice] = msg
    end 
	redirect_to :action => 'show', :id => params[:id]
  end
  
  def add_to_grocery_list
  item_ids = Array.new
   params[:grocery].each_pair{|k, v| item_ids << k if  v == "1" }
    
    item_ids.each do |item|
      puts "#{item} is to be added to the grocery list"
      @grocery_ingredient = GroceryIngredient.new()
      @grocery_ingredient.user_id = current_user.id
      @grocery_ingredient.ingredient_id = item.to_i
      rec_ing = RecipeIngredient.find(:first, :conditions => ["recipe_id = #{params[:id]} AND ingredient_id = #{item}"])
      @grocery_ingredient.qty = rec_ing.qty
      @grocery_ingredient.unit = rec_ing.unit
      if @grocery_ingredient.save
        flash[:notice] = "Items were successfully added to your grocery list"
      else 
        flash[:warning] = "Items were not added to your grocery list - something went wrong.  We are currently trying to fix this problem.  Sorry for any inconvenience"
      end 
    end
    redirect_to :action => 'show', :id => params[:id] 
  end
  
  def comment
    @recipe_comments = RecipeComment.new(:recipe_id => params[:id], :user_id => current_user.id, :comment => params[:comment][:body])
    if @recipe_comments.save
      flash[:notice] = "Your comment has been added."
    end 
    redirect_to :action => "show", :id => params[:id]
  end

  def destroy_comment
    @recipe_comment = RecipeComment.find(params[:id])
    unless @recipe_comment.destroy
      flash[:error] = "Error Deleting Comment"
      redirect_to :action => 'show'
    end
  end
  
  def adjust_ingredient_amt
    @recipe = Recipe.find(params[:id])
    @recipe_comments = @recipe.recipe_comments
    @recipe_ratings = @recipe.recipe_ratings
    @recipe_avg_rating = avg_rating()
    @serving_qty = params[:new_qty][:qty].to_i()
    render :action => 'show'
  end
  
  def makeit
    @recipe = Recipe.find(params[:id])
    @recipe_ingredients = RecipeIngredient.find(:all, :conditions =>{:recipe_id => @recipe.id})
    @user_ingredients = UserIngredient.find(:all, :conditions => {:user_id => current_user.id})
    
      for u_ing in @user_ingredients
        for r_ing in @recipe_ingredients
        if r_ing.ingredient_id== u_ing.ingredient_id and r_ing.unit == u_ing.unit
          if (u_ing.qty - r_ing.qty <0) 
            qty = 0 
          else 
            qty = u_ing.qty - r_ing.qty 
          end
          @user_ingredients = UserIngredient.update (u_ing.id, :qty =>qty)
          
        end
      end
    end
   flash[:notice] = 'User Ingredient quantities successfully decremented.'
   redirect_to :action => 'show'
  end
  
end
