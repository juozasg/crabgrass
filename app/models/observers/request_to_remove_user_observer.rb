class RequestToRemoveUserObserver < ActiveRecord::Observer
  def after_create(request)
    key = rand(Time.now)
    request.group.users.each do |user|
      UserProposedToRemoveUserActivity.create!(:user => request.created_by, :target_user => request.user, :group => request.group, :key => key)
      #Mailer.deliver_request_to_destroy_our_group(request, user)
    end
    UserProposedToRemoveUserActivity.last.description
  end
end
