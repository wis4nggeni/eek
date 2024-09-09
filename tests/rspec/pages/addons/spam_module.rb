class SpamTrap < ControlPanelPage
  set_url_matcher /addons\/settings\/spam/

  element :keyword_search, 'div.filters input[name=filter_by_keyword]'

  # Main box elements
  element :heading, '.align-right div.col.w-16 div.box form h1'
  element :perpage_filter, 'div.col.w-16 div.box form h1 + div.filters ul li:first-child'
  element :perpage_filter_menu, 'div.col.w-16 div.box form h1 + div.filters ul li:first-child div.sub-menu ul'
  element :perpage_manual_filter, 'input[name="perpage"]'

  # Main box's table elements
  elements :spam_trap, 'div.box form div.tbl-wrap table tr'
  element :selected_spam, 'div.box form div.tbl-wrap table tr.selected'

  element :content_header, 'div.box form div.tbl-wrap table tr th:first-child'
  element :date_header, 'div.box form div.tbl-wrap table tr th:nth-child(2)'
  element :ip_header, 'div.box form div.tbl-wrap table tr th:nth-child(3)'
  element :type_header, 'div.box form div.tbl-wrap table tr th:nth-child(4)'
  element :manage_header, 'div.box form div.tbl-wrap table tr th:nth-child(4)'
  element :checkbox_header, 'div.box form div.tbl-wrap table tr th:nth-child(5)'
  element :check_all, 'div.box form div.tbl-wrap table tr th:nth-child(5) input'

  elements :content, 'div.box form div.tbl-wrap table tr td:first-child'
  elements :date, 'div.box form div.tbl-wrap table tr td:nth-child(2)'
  elements :ip_addresses, 'div.box form div.tbl-wrap table tr td:nth-child(3)'
  elements :manage_actions, 'div.box form div.tbl-wrap table tr td:nth-child(4)'

  element :bulk_action, 'form fieldset.tbl-bulk-act select[name="bulk_action"]'
  element :action_submit_button, 'form fieldset.tbl-bulk-act button.submit'

  element :no_results, 'tr.no-results'

  element :view_modal, 'div.spam-modal'
  element :view_modal_header, 'div.spam-modal h1'

  def load
    self.open_dev_menu
    click_link 'Add-Ons'
    self.find('div.tbl-wrap table tr a', :text => 'Spam').click
  end

end
