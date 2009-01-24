require File.dirname(__FILE__) + '/../test_helper'

class WikiTest < Test::Unit::TestCase

  fixtures :users
  fixtures :wikis
  
  def setup
    @orange_id = users(:orange).id
    @blue_id = users(:blue).id
  end

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

    w.unlock

    assert w.editable_by?(users(:blue)), 'blue should be able to edit wiki'
    assert w.editable_by?(users(:red)), 'red should be able to edit wiki'
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

    w.unlock(0)

    assert w.editable_by?(users(:orange), 0), 'orange should be able to edit wiki section 0'
    assert w.editable_by?(users(:red), 0), 'red should be able to edit wiki section 0'
  end

  def test_editable_by
    w = wikis(:multi_section)

    assert w.editable_by?(users(:orange), :all), 'orange should be able to edit whole wiki body'
    assert w.editable_by?(users(:blue), :all), 'blue should be able to edit whole wiki body'

    assert w.editable_by?(users(:orange), 0), 'orange should be able to edit wiki section 0'
    assert w.editable_by?(users(:blue), 0), 'blue should be able to edit wiki section 0'

    # lock all sections
    w.lock(Time.now, users(:orange), :all)

    assert w.editable_by?(users(:orange), :all), 'orange should be able to edit whole wiki body'
    assert !w.editable_by?(users(:blue), :all), 'blue should not be able to edit whole wiki body'

    assert !w.editable_by?(users(:orange), 0), 'orange should not be able to edit wiki section 0'
    assert !w.editable_by?(users(:blue), 0), 'blue should not be able to edit wiki section 0'
  end

  def test_section_editable_by
    w = wikis(:multi_section)

    assert w.editable_by?(users(:orange), :all), 'orange should be able to edit whole wiki body'
    assert w.editable_by?(users(:blue), :all), 'blue should be able to edit whole wiki body'

    assert w.editable_by?(users(:orange), 0), 'orange should be able to edit wiki section 0'
    assert w.editable_by?(users(:blue), 0), 'blue should be able to edit wiki section 0'

    # lock first section
    w.lock(Time.now, users(:orange), 0)

    assert !w.editable_by?(users(:orange), :all), 'orange should not be able to edit whole wiki body'
    assert !w.editable_by?(users(:blue), :all), 'blue should not be able to edit whole wiki body'

    assert w.editable_by?(users(:orange), 0), 'orange should be able to edit wiki section 0'
    assert !w.editable_by?(users(:blue), 0), 'blue should not be able to edit wiki section 0'
  end

  def test_locked_by_id
    w = wikis(:multi_section)

    assert_nil w.locked_by_id(:all), "no one should be the locker of the whole wiki body"
    assert_nil w.locked_by_id(1), "no one should be the locker of the wiki section 1"
    assert_nil w.locked_by_id(0), "no one should be the locker of the wiki section 0"

    # lock all sections
    w.lock(Time.now, users(:orange), :all)

    assert_equal @orange_id, w.locked_by_id(:all), "orange should be the locker of the whole wiki body"
    assert_equal @orange_id, w.locked_by_id(0), "orange should appear as the locker of wiki section 0"
    assert_equal @orange_id, w.locked_by_id(1), "orange should appear as the locker of wiki section 1"
  end

  def test_section_locked_by_id
    w = wikis(:multi_section)

    assert_nil w.locked_by_id(:all), "no one should be the locker of the whole wiki body"
    assert_nil w.locked_by_id(1), "no one should be the locker of the wiki section 1"
    assert_nil w.locked_by_id(0), "no one should be the locker of the wiki section 0"

    # lock one section
    w.lock(Time.now, users(:orange), 1)

    assert_equal @orange_id, w.locked_by_id(:all), "orange should be the locker of the whole wiki body"
    assert_nil w.locked_by_id(0), "no one should appear as the locker of wiki section 0"
    assert_equal @orange_id, w.locked_by_id(1), "orange should appear as the locker of wiki section 1"
  end

  def test_multi_section_save
    w = wikis(:multi_section)

    original_body = w.body.clone
    original_sections = [w.sections[0].clone, w.sections[1].clone]
    updated_sections = ["h1. section header first updated\n\n", "h1. second updated section header\nwith text\n"]

    # lock two sections
    w.lock(Time.now, users(:orange), 0)
    w.lock(Time.now, users(:blue), 1)

    # try to do the wrong thing
    assert_raise ErrorMessage do
      w.smart_save! :body => 'catelope', :user => users(:orange)
    end

    assert_raise ErrorMessage do
      w.smart_save! :body => updated_sections[0], :user => users(:blue), :section => 0
    end

    assert_raise ErrorMessage do
      w.smart_save! :body => updated_sections[0], :user => users(:orange), :section => 1
    end

    assert_equal original_body, w.body, "wiki body shouldn't be updated by invalid saves"

    # try the right thing with section 0
    assert_nothing_raised do
      w.smart_save! :body => updated_sections[0], :user => users(:orange), :section => 0
    end

    expected_body = original_body.gsub(original_sections[0], updated_sections[0])
    assert_equal expected_body, w.body, "wiki section 0 should be updated"

    # repeat for section 1
    assert_nothing_raised do
      w.smart_save! :body => updated_sections[1], :user => users(:blue), :section => 1
    end

    expected_body = original_body.gsub(original_sections[0], updated_sections[0])
    expected_body.gsub!(original_sections[1], updated_sections[1])

    assert_equal expected_body, w.body, "wiki sections 0 and section 1 should be updated"
  end

  def test_wiki_page
  end

  def test_associations
    assert check_associations(Wiki)
  end

end
