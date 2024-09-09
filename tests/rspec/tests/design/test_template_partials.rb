require './bootstrap.rb'

feature 'Template Partials' do
  before(:each) do
    ee_config(item: 'multiple_sites_enabled', value: 'y')
    ee_config(item: 'save_tmpl_files', value: 'n')
    cp_session
    @page = TemplatePartials.new
    @page.load
    no_php_js_errors
  end

  it 'displays' do
    @page.all_there?.should == true
    @page.partials.should have(13).items
  end

  it 'can filter by keyword' do
    @page.keyword_search.set 'global'
    @page.keyword_search.send_keys(:enter)

    no_php_js_errors

    @page.partials.should have(8).items
  end

  it 'can find templates that use a partial' do
    @page.partials[6].manage.find.click

    no_php_js_errors

    @page.page_title.text.should include 'Search Results'
    @page.page_title.text.should include '{global_stylesheets}'
    @page.partials.should have(9).items # Yeah, not technically 'partials' but the selectors work
  end

  it 'can navigate to edit form' do
    @page.partials[6].manage.edit.click

    no_php_js_errors

    form = TemplatePartialForm.new
  end

  it 'should validate the form' do
    @page.create_new_button.click

    form = TemplatePartialForm.new
    form.name.set 'lots of neat stuff'
    form.name.trigger 'blur'
    form.wait_for_error_message_count(1)
    should_have_error_text(form.name, 'The name you submitted may only contain alpha-numeric characters, underscores, and dashes')
    should_have_form_errors(form)
  end

  it 'can create a new partial' do
    skip 'Cannot figure out how to populate a codemirror form element' do
    end
    @page.create_new_button.click

    no_php_js_errors

    form = TemplatePartialForm.new
    form.name.set 'rspec-test'

    form.should have_contents
    form.should have_contents_editor

    form.contents.click
    form.contents_editor.send_keys 'Lorem ipsum...'

    form.save_button.click

    no_php_js_errors

    @page.should have_alert
    @page.alert.text.should include 'Template Partial Created'
    @page.alert.text.should include 'rspec-testicle'
  end

  it 'can remove a partial' do
    @page.partials[0].bulk_action_checkbox.click
    @page.wait_for_bulk_action

    @page.has_bulk_action?.should == true
    @page.has_action_submit_button?.should == true

    @page.bulk_action.select 'Remove'
    @page.action_submit_button.click

    @page.wait_for_modal_submit_button
    @page.modal_submit_button.click

    no_php_js_errors

    @page.should have_alert
    @page.should have_alert_success
    @page.partials.should have(12).items
  end
end
