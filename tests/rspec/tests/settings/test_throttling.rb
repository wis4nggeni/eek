require './bootstrap.rb'

feature 'Access Throttling Settings' do

  before(:each) do
    cp_session
    @page = ThrottlingSettings.new
    @page.load
    no_php_js_errors
  end

  it 'shows the Access Throttling Settings page' do
    @page.all_there?.should == true
  end

  it 'should load current settings into form fields' do
    @page.enable_throttling.value.should == ee_config(item: 'enable_throttling')
    @page.banish_masked_ips.value.should == ee_config(item: 'banish_masked_ips')
    @page.lockout_time.value.should == ee_config(item: 'lockout_time')
    @page.max_page_loads.value.should == ee_config(item: 'max_page_loads')
    @page.time_interval.value.should == ee_config(item: 'time_interval')
    @page.banishment_type.has_checked_radio(ee_config(item: 'banishment_type')).should == true
    @page.banishment_url.value.should == ee_config(item: 'banishment_url')
    @page.banishment_message.value.should == ee_config(item: 'banishment_message')
  end

  it 'should validate the form' do
    integer_error = 'This field must contain an integer.'

    @page.lockout_time.set 'sdfsdfsd'
    @page.submit

    no_php_js_errors
    should_have_form_errors(@page)
    @page.should have_text 'Attention: Settings not saved'
    should_have_error_text(@page.lockout_time, integer_error)

    # AJAX validation
    @page.load
    @page.lockout_time.set 'sdfsdfsd'
    @page.lockout_time.trigger 'blur'
    @page.wait_for_error_message_count(1)
    should_have_error_text(@page.lockout_time, integer_error)
    should_have_form_errors(@page)

    @page.max_page_loads.set 'sdfsdfsd'
    @page.max_page_loads.trigger 'blur'
    @page.wait_for_error_message_count(2)
    should_have_error_text(@page.max_page_loads, integer_error)
    should_have_form_errors(@page)

    @page.time_interval.set 'sdfsdfsd'
    @page.time_interval.trigger 'blur'
    @page.wait_for_error_message_count(3)
    should_have_error_text(@page.time_interval, integer_error)
    should_have_form_errors(@page)

    # Fix everything
    @page.lockout_time.set '5'
    @page.lockout_time.trigger 'blur'
    @page.wait_for_error_message_count(2)
    should_have_no_error_text(@page.lockout_time)
    should_have_form_errors(@page)

    @page.max_page_loads.set '15'
    @page.max_page_loads.trigger 'blur'
    @page.wait_for_error_message_count(1)
    should_have_no_error_text(@page.max_page_loads)
    should_have_form_errors(@page)

    @page.time_interval.set '8'
    @page.time_interval.trigger 'blur'
    @page.wait_for_error_message_count(0)
    should_have_no_error_text(@page.time_interval)
    should_have_no_form_errors(@page)
  end

  it 'should reject XSS' do
    @page.banishment_url.set $xss_vector
    @page.banishment_url.trigger 'blur'
    @page.wait_for_error_message_count(1)
    should_have_error_text(@page.banishment_url, $xss_error)
    should_have_form_errors(@page)

    @page.banishment_message.set $xss_vector
    @page.banishment_message.trigger 'blur'
    @page.wait_for_error_message_count(2)
    should_have_error_text(@page.banishment_url, $xss_error)
    should_have_error_text(@page.banishment_message, $xss_error)
    should_have_form_errors(@page)
  end

  it 'should save and load the settings' do
    @page.enable_throttling_toggle.click
    @page.banish_masked_ips_toggle.click
    @page.lockout_time.set '60'
    @page.max_page_loads.set '40'
    @page.time_interval.set '30'
    @page.banishment_type.choose_radio_option('404')
    @page.banishment_url.set 'http://yahoo.com'
    @page.banishment_message.set 'You are banned'
    @page.submit

    @page.enable_throttling.value.should == 'y'
    @page.banish_masked_ips.value.should == 'n'
    @page.lockout_time.value.should == '60'
    @page.max_page_loads.value.should == '40'
    @page.time_interval.value.should == '30'
    @page.banishment_type.has_checked_radio('404').should == true
    @page.banishment_url.value.should == 'http://yahoo.com'
    @page.banishment_message.value.should == 'You are banned'
  end
end
