require './bootstrap.rb'

feature 'Status Create/Edit' do

  before(:each) do
    skip "Needs fleshing out for new channel manager" do
    end
    cp_session
    @page = StatusCreate.new
    @page.load_view_for_status_group(1)
    no_php_js_errors
  end

  it 'shows the Status Create/Edit page' do
    @page.load_create_for_status_group(1)
    @page.should have_status
    @page.should have_highlight
    @page.should have_status_access
    @page.should have_text 'Create Status'
  end

  it 'should validate fields' do
    @page.load_create_for_status_group(1)
    @page.submit

    no_php_js_errors
    should_have_form_errors(@page)
    @page.should have_text 'Cannot Create Status'
    should_have_error_text(@page.status, $required_error)

    @page.load_view_for_status_group(1)
    @page.load_create_for_status_group(1)

    # AJAX validation
    # Required name
    @page.status.trigger 'blur'
    @page.wait_for_error_message_count(1)
    should_have_error_text(@page.status, $required_error)
    should_have_form_errors(@page)

    @page.status.set 'Test'
    @page.status.trigger 'blur'
    @page.wait_for_error_message_count(0)
    should_have_no_error_text(@page.status)
    should_have_no_form_errors(@page)

    # Duplicate status name
    @page.status.set 'open'
    @page.status.trigger 'blur'
    @page.wait_for_error_message_count(1)
    should_have_error_text(@page.status, 'A status already exists with the same name.')
    should_have_form_errors(@page)

    @page.status.set 'Test'
    @page.status.trigger 'blur'
    @page.wait_for_error_message_count(0)
    should_have_no_error_text(@page.status)
    should_have_no_form_errors(@page)

    # Minicolors should show up
    @page.highlight.trigger 'focus'
    @page.wait_until_color_panel_visible(2)
    @page.should have_color_panel

    # We MUST mousedown to hide the minicolors panel
    @page.status.trigger 'mousedown'
    @page.wait_until_color_panel_invisible(2)
    # Seems to be the accepted way to check for invisible elements
    @page.should have_selector('div.minicolors-panel', visible: false)

    # Invalid hex
    @page.highlight.trigger 'focus'
    @page.highlight.set '00000g'
    @page.highlight.trigger 'blur'
    @page.status.trigger 'mousedown'
    @page.wait_until_color_panel_invisible(2)
    @page.highlight.value.should  == '#000000'

    @page.highlight.trigger 'focus'
    @page.highlight.set '0000'
    @page.highlight.trigger 'blur'
    @page.status.trigger 'mousedown'
    @page.wait_until_color_panel_invisible(2)
    @page.highlight.value.should  == ''

    @page.highlight.trigger 'focus'
    @page.highlight.set 'ff'
    @page.highlight.trigger 'blur'
    @page.status.trigger 'mousedown'
    @page.wait_until_color_panel_invisible(2)
    @page.highlight.value.should  == ''

    @page.highlight.trigger 'focus'
    @page.highlight.set 'fff'
    @page.highlight.trigger 'blur'
    @page.status.trigger 'mousedown'
    @page.wait_until_color_panel_invisible(2)
    @page.highlight.value.should  == '#ffffff'
  end

  it 'should reject XSS' do
    @page.load_create_for_status_group(1)

    @page.status.set $xss_vector
    @page.status.trigger 'blur'
    @page.wait_for_error_message_count(1)
    should_have_error_text(@page.status, $xss_error)
    should_have_form_errors(@page)

    @page.highlight.set $xss_vector
    @page.highlight.trigger 'blur'
    @page.highlight.value.should == ''
  end

   it 'should repopulate the form on validation error' do
    @page.load_create_for_status_group(1)

    @page.status.set 'Open'
    @page.status_access[0].set false
    @page.submit

    @page.should have_text 'Cannot Create Status'
    should_have_error_text(@page.status, 'A status already exists with the same name.')

    @page.status.value.should == 'Open'
    @page.status_access[0].checked?.should == false
  end

  it 'should save a new status group and load edit form' do
    @page.load_create_for_status_group(1)

    @page.status.set 'Test'
    @page.highlight.set '333'
    @page.status.trigger 'mousedown'
    @page.status_access[0].set false
    @page.submit
    no_php_js_errors

    @page.should have_text 'Status Created'

    @page.load_view_for_status_group(1)
    @page.load_edit_for_status(4)
    no_php_js_errors

    @page.should have_text 'Edit Status'
    should_have_no_form_errors(@page)

    @page.status.value.should == 'Test'
    @page.highlight.value.should == '#333333'
    @page.status_access[0].checked?.should == false

    # Make sure we can edit
    @page.status.set 'Test2'
    @page.status.trigger 'change'
    @page.status_access[0].set true
    @page.submit
    no_php_js_errors

    @page.should have_text 'Status Updated'

    @page.load_view_for_status_group(1)
    @page.load_edit_for_status(4)

    @page.should have_text 'Edit Status'
    should_have_no_form_errors(@page)

    @page.status.value.should == 'Test2'
    @page.highlight.value.should == '#333333'
    @page.status_access[0].checked?.should == true
  end

  it 'should not allow open and closed status names to be edited' do
    @page.load_view_for_status_group(1)
    @page.load_edit_for_status(1)
    @page.status.disabled?.should eq true
    no_php_js_errors

    @page.load_view_for_status_group(1)
    @page.load_edit_for_status(2)
    @page.status.disabled?.should eq true
  end
end
