class DiscussionPageController < BasePageController

  def show
    @comment_header = ""
  end
  
  protected
  
  def setup_view
    @show_reply = true
    @show_attach = true
  end
  
end