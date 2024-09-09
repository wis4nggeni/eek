require './bootstrap.rb'

feature 'Throttling Log' do

  before(:each) do
    cp_session

    @page = ThrottleLog.new
  end

  before(:each, :pregen => true) do
    @page.generate_data(count: 150)
    @page.generate_data(count: 100, locked_out: true)
  end

  before(:each, :enabled => false) do
    ee_config(item: 'enable_throttling', value: 'n')
    @page.load
    no_php_js_errors

    # These should always be true at all times if not something has gone wrong
    @page.displayed?
    @page.heading.text.should eq 'Access Throttling Logs'

    @page.should_not have_keyword_search
    @page.should_not have_submit_button
    @page.should_not have_perpage_filter
  end

  before(:each, :enabled => true) do
    ee_config(item: 'enable_throttling', value: 'y')
    @page.load
    no_php_js_errors

    # These should always be true at all times if not something has gone wrong
    @page.displayed?
    @page.heading.text.should eq 'Access Throttling Logs'
    @page.should have_keyword_search
    @page.should have_submit_button
    @page.should have_perpage_filter
  end

  context 'when throttling is disabled' do
    it 'shows the Turn Throttling On button', :enabled => false, :pregen => true do
      @page.should have_no_results
      @page.should have_selector('a', :text => 'Turn Throttling On')
    end
  end

  context 'when throttling is enabled' do
    it 'shows the Access Throttling Logs page', :enabled => true, :pregen => true do
      @page.should have_remove_all
      @page.should have_pagination

      @page.perpage_filter.text.should eq "show (25)"

      @page.should have(6).pages
      @page.pages.map {|name| name.text}.should == ["First", "1", "2", "3", "Next", "Last"]

      @page.should have(25).items # Default is 25 per page
    end

    # Confirming phrase search
    it 'searches by phrases', :enabled => true, :pregen => true do
      our_ip = "172.16.11.42"

      @page.generate_data(count: 1, timestamp_max: 0, ip_address: our_ip)
      @page.load

      # Be sane and make sure it's there before we search for it
      @page.should have_text our_ip

      @page.keyword_search.set "172.16.11"
      @page.keyword_search.send_keys(:enter)

      @page.heading.text.should eq 'Search Results we found 1 results for "172.16.11"'
      @page.keyword_search.value.should eq "172.16.11"
      @page.should have_text our_ip
      @page.should have(1).items
    end

    it 'shows no results on a failed search', :enabled => true, :pregen => true do
      our_ip = "NotFoundHere"

      @page.keyword_search.set our_ip
      @page.keyword_search.send_keys(:enter)

      @page.heading.text.should eq 'Search Results we found 0 results for "' + our_ip + '"'
      @page.keyword_search.value.should eq our_ip
      @page.should have_text our_ip
      @page.should have_perpage_filter

      @page.should have_no_results

      @page.should_not have_pagination
      @page.should_not have_remove_all
    end

    it 'can change page size', :enabled => true, :pregen => true do
      @page.perpage_filter.click
      @page.wait_until_perpage_filter_menu_visible
      @page.perpage_filter_menu.click_link "25 results"

      @page.perpage_filter.text.should eq "show (25)"
      @page.should have(25).items
      @page.should have_pagination
      @page.should have(6).pages
      @page.pages.map {|name| name.text}.should == ["First", "1", "2", "3", "Next", "Last"]
    end

    it 'can set a custom limit', :enabled => true, :pregen => true do
      @page.perpage_filter.click
      @page.wait_until_perpage_manual_filter_visible
      @page.perpage_manual_filter.set "42"
      @page.execute_script("$('div.filters input[type=text]').closest('form').submit()")

      @page.perpage_filter.text.should eq "show (42)"
      @page.should have(42).items
      @page.should have_pagination
      @page.should have(6).pages
      @page.pages.map {|name| name.text}.should == ["First", "1", "2", "3", "Next", "Last"]
    end

    it 'can combine phrase search with filters', :enabled => true, :pregen => true do
      our_ip = "172.16.11.42"

      @page.generate_data(count: 27, timestamp_max: 0, ip_address: our_ip)
      @page.load
      no_php_js_errors

      @page.perpage_filter.click
      @page.wait_until_perpage_filter_menu_visible
      @page.perpage_filter_menu.click_link "25"
      no_php_js_errors

      @page.keyword_search.set "172.16.11"
      @page.keyword_search.send_keys(:enter)

      @page.perpage_filter.text.should eq "show (25)"
      @page.heading.text.should eq 'Search Results we found 27 results for "172.16.11"'
      @page.keyword_search.value.should eq "172.16.11"
      @page.should have_text our_ip
      @page.should have(25).items
      @page.should have_pagination
      @page.should have(5).pages
      @page.pages.map {|name| name.text}.should == ["First", "1", "2", "Next", "Last"]
    end

    # Confirming the log deletion action
    # it 'can remove a single entry', :enabled => true, :pregen => true do
    #    our_action = "Rspec entry to be deleted"
    #
    #    @page.generate_data(count: 1, timestamp_max: 0, action: our_action)
    #    @page.load
    #
    #    log = @page.find('section.item-wrap div.item', :text => our_action)
    #    log.find('li.remove a').click
    #
    #    @page.should have_alert
    #    @page.should have_no_content our_action
    # end

    it 'can remove all entries', :enabled => true, :pregen => true do
      @page.remove_all.click # Activates a modal

      @page.wait_until_modal_visible
      @page.modal_title.text.should eq "Confirm Removal"
      @page.modal.text.should include "You are attempting to remove the following items, please confirm this action."
      @page.modal.text.should include "Access Throttling Logs: All"
      @page.modal_submit_button.click # Submits a form

      @page.should have_alert
      @page.alert.text.should eq "Logs Deleted 250 log(s) deleted from Throttling logs"

      @page.should have_no_results
      @page.should_not have_pagination
    end

    # Confirming Pagination behavior
    it 'shows the Prev button when on page 2', :enabled => true, :pregen => true do
      click_link "Next"

      @page.should have_pagination
      @page.should have(7).pages
      @page.pages.map {|name| name.text}.should == ["First", "Previous", "1", "2", "3", "Next", "Last"]
    end

    it 'does not show Next on the last page', :enabled => true, :pregen => true do
      click_link "Last"

      @page.should have_pagination
      @page.should have(6).pages
      @page.pages.map {|name| name.text}.should == ["First", "Previous", "8", "9", "10", "Last"]
    end

    it 'does not lose a filter value when paginating', :enabled => true, :pregen => true do
      @page.perpage_filter.click
      @page.wait_until_perpage_filter_menu_visible
      @page.perpage_filter_menu.click_link "25 results"
      no_php_js_errors

      @page.perpage_filter.text.should eq "show (25)"
      @page.should have(25).items

      click_link "Next"

      @page.perpage_filter.text.should eq "show (25)"
      @page.should have(25).items
      @page.should have_pagination
      @page.should have(7).pages
      @page.pages.map {|name| name.text}.should == ["First", "Previous", "1", "2", "3", "Next", "Last"]
    end

    it 'will paginate phrase search results', :enabled => true, :pregen => true do
      @page.generate_data(count: 35, timestamp_max: 0, ip_address: "172.16.11.42")
      @page.load
      no_php_js_errors

      @page.perpage_filter.click
      @page.wait_until_perpage_filter_menu_visible
      @page.perpage_filter_menu.click_link "25"
      no_php_js_errors

      @page.keyword_search.set "172.16.11"
      @page.keyword_search.send_keys(:enter)
      no_php_js_errors

      # Page 1
      @page.heading.text.should eq 'Search Results we found 35 results for "172.16.11"'
      @page.keyword_search.value.should eq "172.16.11"
      @page.items.should_not have_text "10.0"
      @page.perpage_filter.text.should eq "show (25)"
      @page.should have(25).items
      @page.should have_pagination
      @page.should have(5).pages
      @page.pages.map {|name| name.text}.should == ["First", "1", "2", "Next", "Last"]

      click_link "Next"

      # Page 2
      @page.heading.text.should eq 'Search Results we found 35 results for "172.16.11"'
      @page.keyword_search.value.should eq "172.16.11"
      @page.items.should_not have_text "10.0"
      @page.perpage_filter.text.should eq "show (25)"
      @page.should have(10).items
      @page.should have_pagination
      @page.should have(5).pages
      @page.pages.map {|name| name.text}.should == ["First", "Previous", "1", "2", "Last"]
    end
  end
end
