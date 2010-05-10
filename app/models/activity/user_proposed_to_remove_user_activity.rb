class UserProposedToRemoveUserActivity < Activity
  validates_format_of :subject_type, :with => /User/
  validates_format_of :object_type, :with => /User/
  validates_presence_of :subject_id
  validates_presence_of :object_id

  alias_attr :user, :subject
  alias_attr :target_user, :object

  belongs_to :group, :foreign_key => :related_id

  before_create :set_access
  def set_access
    if user.profiles.public.may_see_groups? and group.profiles.public.may_see_members?
      self.access = Activity::PUBLIC
    end
  end


  def description(view=nil)
    require 'ruby-debug';debugger;1
    I18n.t(:request_to_remove_coordinator_user_description,
      {:group => group_span(group),
        :group_type => group.group_type.downcase,
        :user => user_span(user),
        :target_user => user_span(target_user),
        :tooltip => ""})
  end

  def icon
    'minus'
  end


end

