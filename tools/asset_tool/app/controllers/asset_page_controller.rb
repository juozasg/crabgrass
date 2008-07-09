class AssetPageController < BasePageController
  before_filter :fetch_asset
  javascript :extra
  stylesheet 'asset'

  include AssetPageHelper

  def show
  end

  # note, massive duplication both here and in the view
  def create
    @page_class = AssetPage
    if request.post?
      if params[:asset][:uploaded_data] == ""
        flash[:error] = "You must select a file."
        return render(:action => 'create')
      end
      
      @page = create_new_page(@page_class)
      @asset = Asset.new params[:asset]
      @page.data = @asset
      if @page.title.any?
        @asset.filename = @page.title + @asset.suffix
      else
        @page.title = @asset.basename
      end
      if @page.save
        add_participants!(@page, params)
        return redirect_to(page_url(@page))
      else
        message :object => @page
      end
    end
  end

  def update
    @page.data.uploaded_data = params[:asset]
    @page.data.filename = @page.title + @page.data.suffix
    if @page.data.save
      @asset.generate_non_image_thumbnail if @asset.may_thumbnail?
      return redirect_to(page_url(@page))
    else
      message :object => @page
    end
  end

  def destroy_version
    asset_version = @page.data.versions.find_by_version(params[:id])
    asset_version.destroy
    respond_to do |format|
      format.html do
        message(:success => "file version deleted")
        redirect_to(page_url(@page))
      end
      format.js { render(:update) {|page| page.visual_effect :fade, "asset_#{asset_version.asset_id}_version_#{asset_version.version}", :duration => 0.5} }
    end
  end

  # xhr request
  def generate_preview
    @asset.generate_non_image_thumbnail
    render :update do |page|
      page.replace_html 'preview-area', asset_link_with_preview(@asset)
    end
  end

  protected
  
  def fetch_asset
    @asset = @page.data if @page
  end
  
  def setup_view
    @show_attach = false
    @show_posts = true
  end
  
end
