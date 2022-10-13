class PagerFilterPreference < PagerFilter

  def close_modal_btn; end

  def no_filter_btn; end

  def search_btn; end

  def restore_filter_btn; end

  def display_filters(quick_filter: false)
    quick_filter ? nil : super
  end

  def set_quick_filter; end

  def filter_body
    inner_filter_body
    display_filters_container
    reset_filters_body
  end

  render do
    filter_body if loaded && filters.count > 0
  end

end