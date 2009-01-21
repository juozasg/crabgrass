require File.dirname(__FILE__) + '/../test_helper'

class WikiTest < Test::Unit::TestCase

  fixtures :users
  fixtures :wikis
  
  def test_creation_group_space
    g = Group.create! :name => 'robots'

    a = WikiPage.create :title => 'x61'
    a.add g; a.save

    b = WikiPage.create :title => 'x61'
    b.add g;
 
    assert_equal 'x61', a.name, 'name should equal title'
    assert b.name_taken?, 'name should already be taken'
    assert !b.valid?, 'should not be able to have two wikis with the same name'
  end
  
  def test_lock
    w = Wiki.create :body => 'watermelon'
    w.lock(Time.now, users(:blue))
    
    assert w.locked?, 'locked should be true'
    assert w.editable_by?(users(:blue)), 'blue should be able to edit wiki'
    assert !w.editable_by?(users(:red)), 'red should not be able to edit wiki'

    assert !w.editable_by?(users(:blue), 0), 'blue should not be able to edit wiki section 0'
    assert !w.editable_by?(users(:red), 0), 'red should not be able to edit wiki section 0'
  end
  
  
  def test_saving
    w = Wiki.create :body => 'watermelon'
    w.lock(Time.now, users(:blue))
    
    # version is too old
    assert_raise ErrorMessage do
      w.smart_save! :body => 'catelope', :version => -1, :user => users(:blue)
    end
    
    # already locked
    assert_raise ErrorMessage do
      w.smart_save! :body => 'catelope', :user => users(:red)
    end
    
    assert_nothing_raised do
      w.smart_save! :body => 'catelope', :user => users(:blue)
    end

  end
  
  def test_section_lock
    w = wikis(:multi_section)
    
    w.lock(Time.now, users(:orange), 0)
    assert w.locked?(0), 'locked section (0) should be true'

    assert w.editable_by?(users(:orange), 0), 'orange should be able to edit wiki section 0'
    assert !w.editable_by?(users(:red), 0), 'red should not be able to edit wiki section 0'

    assert w.editable_by?(users(:orange), 1), 'orange should be able to edit wiki section 1'
    assert w.editable_by?(users(:blue), 1), 'blue should be able to edit wiki section 1'
  end
  
  def test_wiki_page
  end

  def test_associations
    assert check_associations(Wiki)
  end
  
end
