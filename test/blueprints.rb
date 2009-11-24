require 'machinist/active_record'
require 'sham'
require 'faker'

#
# Common
#

def created_date(average_days = 30)
  (average_days + 5 + rand(5)).days.ago.to_s(:db)
end

def updated_date(average_days = 30)
  (average_days + rand(5)).days.ago.to_s(:db)
end

def boolean
  rand(2) == 1 ? true : false
end

Sham.title            { Faker::Lorem.words(3).join(" ").capitalize }
Sham.email            { Faker::Internet.email }
Sham.login            { Faker::Internet.user_name.gsub(/[^a-z]/, "") }
Sham.display_name     { Faker::Name.name }
Sham.summary          { Faker::Lorem.paragraph }

#
# Site
#
Site.blueprint do
  # make sites available from functional tests
  domain       "test.host"
  email_sender "robot@$current_host"
end

#
# Users
#
User.blueprint do
  login
  display_name
  email
  salt              { Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") }
  crypted_password  { Digest::SHA1.hexdigest("--#{salt}--#{login}--") }

  created_at        { created_date }
  last_seen_at      { updated_date }
end

#
# Groups
#

# requires :user
def Group.make_owned_by(attributes)
  raise "Missing keys (:user) are required for this blueprint" if !attributes.has_key?(:user)
  user = attributes.delete :user
  group = Group.make_unsaved(attributes)
  group.created_by = user
  group.save!
  group
end

Group.blueprint do
  full_name       { Sham.title }
  name            { full_name.gsub(/[^a-z]/,"") }
end

Committee.blueprint do
  name            { Sham.title.gsub(/[^a-z]/,"")[0, 10] }
end

Council.blueprint do
end

Network.blueprint do
  full_name       { Sham.title }
  name            { full_name.gsub(/[^a-z]/,"") }
end

#
# Pages
#

# requieres :owner in attributes
def Page.make_owned_by(attributes, machinist_attributes = {})
  page = Page.make_unsaved(machinist_attributes)
  attributes.reverse_merge!(page.attributes)
  page = Page.build!(attributes)
  page.save!
  page.reload
end

# By default we allways make pages with this blueprint owned by users
# if you want make pages owned by groups or users with specific attributes
# check out make_page_owned_by method
def make_a_page
  title
  summary
  created_at        { created_date }
  updated_at        { updated_date }
  stars_count       { 0 }
  views_count       { rand(100) }
  resolved          { boolean }
end

WikiPage.blueprint do
  make_a_page
end

DiscussionPage.blueprint do
  make_a_page
end

Page.blueprint do
  make_a_page
end

#
# UserParticipation
#
UserParticipation.blueprint do
  access  1
  watch   false
end

#
# Wiki
#
Wiki.blueprint do
  version 1
  body_html { Faker::Lorem.paragraph }
  body  { body_html }
  user_id { User.make.id }
end

#
# Others
#
RateManyPage.blueprint {}

Poll.blueprint {}
RankingPoll.blueprint {}
RatingPoll.blueprint {}

Discussion.blueprint {}

# requieres :page in attributes
def Post.make_comment_to(attributes, machinist_attributes = {})
  post = Post.make_unsaved(machinist_attributes)
  attributes.reverse_merge!(post.attributes)
  attributes.merge! :page => page
  post = Page.build! attributes
  page.save!
  page.reload
end

Post.blueprint do
  discussion { Discussion.make }
  body       { Faker::Lorem.paragraph }
  user       { User.make }
end
