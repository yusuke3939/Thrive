class ItemsController < ApplicationController
  before_action :set_items, only:[:show, :edit, :update, :destroy, :buy, :buypage]
  before_action :set_category
  before_action :set_card, only:[:buy, :buypage]
  
  def index
    @items = Item.where.not(is_deleted: 1).order(created_at: "DESC").limit(10)
  end
  
  def list
    @ladys= Item.where(category_id: 158..336).order(created_at: "DESC").limit(10)
    @mens= Item.where(category_id: 337..466).order(created_at: "DESC").limit(10)
    @electricals = Item.where(category_id: 953..1027).order(created_at: "DESC").limit(10)
    @hobbys = Item.where(category_id: 764..864).order(created_at: "DESC").limit(10)
  end

  def new
    @item = Item.new
    @item.item_images.new
  end

  def create
    @item = Item.new(item_params)
    if @item.save
      redirect_to item_path(@item), notice: '商品の出品に成功しました'
    else
      flash.now[:alert] = '出品できませんでした。入力に不備があります'
      render :new
    end
  end

  
  def show
    @images = ItemImage.where(item_id: @item.id)
    @image = ItemImage.where(item_id: @item.id).first
    @comment = Comment.new
    @comments = @item.comments.includes(:user)
    @prevItem = Item.where('id < ?', @item.id).maximum(:id)
    @nextItem = Item.where('id > ?', @item.id).minimum(:id)
  end
  
  def edit
    if current_user.id == @item.user_id
      @image = ItemImage.where(item_id: @item.id)
      @count = @item.item_images.count
    else
      redirect_to item_path(@item)
    end
  end
  
  def update
    @parents = Category.where('ancestry is null')
    @categories = Category.all
    @children = @parents.map {|p| p.children.map {|c| Array.new << c.children}}
    gon.children = @parents.map {|p| Array.new << p.children}
    gon.grandchildren = @children
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

  def set_category
    @parents = Category.first(13)
    @categories = Category.all
    @children = @parents.map {|p| p.children.map {|c| Array.new << c.children}}
    gon.children = @parents.map {|p| Array.new << p.children}
    gon.grandchildren = @children
  end
  
  def buypage
    if current_user.id == @item.user_id
      redirect_to item_path(@item)
    elsif @item.is_deleted
      redirect_to item_path(@item)
    end
    gon.payjp_key = ENV["PAYJP_KEY"]
    @address = Address.find_by(user_id: current_user)
  end

  def buy
    if @card.present?
    @item.update!(is_deleted: 1, buyer_id: current_user.id)
      charge = Payjp::Charge.create(
        amount: @item.price,
        customer: Payjp::Customer.retrieve(@card.customer_id),
        currency: 'jpy'
      )
      flash[:notice] = '購入が完了しました'
    else
      redirect_back(fallback_location: root_path)
      flash[:alert] = '購入ができません。入力に不備がありますのでご確認ください。'
    end
  end
  
  def search
    @items = Item.search(params[:q])
  end

  private
  def item_params
    params.require(:item).permit(:name, :description, :brand, :category_id, :size_id, :condition_id, :delivery_fee_id, :delivery_from_id, :delivery_method_id, :delivery_day_id, :price, item_images_attributes: [:image]).merge(user_id: current_user.id)
  end

  def item_update_params
    params.require(:item).permit(:name, :description, :brand, :category_id, :size_id, :condition_id, :delivery_fee_id, :delivery_from_id, :delivery_method_id, :delivery_day_id, :price, item_images_attributes: [:image,:_destroy,:id]).merge(user_id: current_user.id)
  end

  def set_items
    item_ids = Item.ids
    if (params[:id].to_i <= item_ids.max) && (item_ids.include?(params[:id].to_i))
      @item = Item.find(params[:id])
    else
      redirect_to list_items_path
    end
  end

  def set_card
    Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
    @card = Card.find_by(user_id: current_user.id)
    if @card
    customer = Payjp::Customer.retrieve(@card.customer_id)
      @cards = customer.cards.retrieve(@card.card_id)
      @brand = @cards.brand
      case @brand
      when "Visa"
        @card_brand = "credit-card_visa.png"
      when "MasterCard"
        @card_brand = "credit-card_master.png"
      when "JCB"
        @card_brand = "credit-card_jcb.png"
      when "American Express"
        @card_brand = "credit-card_american.png"
      when "Diners Club"
        @card_brand = "credit-card_diners.png"
      when "Discover"
        @card_brand = "credit-card_discover.png"
      end
      @month = @cards.exp_month.to_s
      @year = @cards.exp_year.to_s.slice(2,3)
    end
  end
end
