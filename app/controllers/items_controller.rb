class ItemsController < ApplicationController
  before_action :set_category
  before_action :set_items, only:[:show, :edit, :update, :destroy]
  def index
    @parents = Category.all.limit(13)
    @lady = Category.find(1)
    @lady_children = @lady.children
    @ladies_item = Category.where(ancestry: "1/14")
    gon.names = @parents
  end

  def new
    @item = Item.new
    @item.item_images.new
    @parents = Category.all.limit(13)
    @categories = Category.all
    @children = @parents.map {|p| p.children.map {|c| Array.new << c.children}}
    gon.children = @parents.map {|p| Array.new << p.children}
    gon.grandchildren = @children

  end

  def create
    @item = Item.new(item_params)
    @parents = Category.all.limit(13)
    @categories = Category.all
    @children = @parents.map {|p| p.children.map {|c| Array.new << c.children}}
    gon.children = @parents.map {|p| Array.new << p.children}
    gon.grandchildren = @children
    if @item.save
      redirect_to root_path, notice: '商品の出品に成功しました'
    else
      flash.now[:alert] = '出品に失敗しました'
      render :new
    end
  end

  def top
    # @ladys = Item.where(category_id: 1)
    # @mens = Item.where(category_id: 2)
    # @electrical = Item.where(category_id: 8)
    # @hobby = Item.where(category_id: 6)
  end

  def set_category
    @parents = Category.parent
    gon.categories = @category
    @lady = Category.find(1)
    @lady_children = @lady.children
    # @lady_child = @lady.children 
    gon.lady_children = @lady_children
    gon.indirects = @lady_children[0].children
  end
  
  def show
    @images = ItemImage.where(item_id: @item.id)
    @image = ItemImage.where(item_id: @item.id).first
  end
  
  def edit
    @image = ItemImage.where(item_id: @item.id)
    @count = @item.item_images.count

    @parents = Category.all.limit(13)
    @categories = Category.all
    @children = @parents.map {|p| p.children.map {|c| Array.new << c.children}}
    gon.children = @parents.map {|p| Array.new << p.children}
    gon.grandchildren = @children
  end
  
  def update
    if @item.update(item_update_params)
      redirect_to item_path(@item.id)
    else
      render :edit
    end
  end

  def destroy
    if @item.destroy
      redirect_to root_path
    else
      render :edit
    end
  end
  
private
  def item_params
    params.require(:item).permit(:name, :description, :brand, :category_id, :size_id, :condition_id, :delivery_fee_id, :delivery_from_id, :delivery_method_id, :delivery_day_id, :price, item_images_attributes: [:image]).merge(user_id: current_user.id)
  end

  def item_update_params
    params.require(:item).permit(:name, :description, :brand, :category_id, :size_id, :condition_id, :delivery_fee_id, :delivery_from_id, :delivery_method_id, :delivery_day_id, :price, item_images_attributes: [:image,:_destroy,:id]).merge(user_id: current_user.id)
  end

  def set_items
    @item = Item.find(params[:id])
  end
  

end
