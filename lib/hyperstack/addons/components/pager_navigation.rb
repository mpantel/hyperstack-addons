class PagerNavigation < Base::Component

  param :page_size
  param :rows_found
  param :current_page
  fires :set_page
  param :btn_css, default: "btn-secondary" #btn-primary, btn-secondary

  def current_page_local
    current_page > number_of_pages ? 1 : current_page
  end

  def number_of_pages
    if (page_size || 0) > 0
      ((rows_found / page_size) + (rows_found % page_size > 0 ? 1 : 0)).to_i
    else
      1
    end
  end

  def pager_start
    current_page_local - 10 < 1 ? 1 : (current_page_local - 10)
  end

  def pager_end
    (current_page_local + 10) > number_of_pages ? number_of_pages : (current_page_local + 10)
  end

  render do
    DIV(className: "btn-group btn-group-sm") do
      SPAN(className: "btn #{btn_css}") { "Σύνολο: #{rows_found} εγγραφ#{rows_found == 1 ? 'ή' : 'ών'} (Σελίδα: #{current_page_local} από #{number_of_pages})" }
      begin
        A(className: "btn #{btn_css}") do
          SPAN(className: "fa fa-fast-backward fa-fw").
            on(:click) { set_page! pager_start - 1 }
        end if pager_start > 1
        A(className: "btn #{btn_css}") do
          SPAN(className: "fa fa-backward fa-fw").
            on(:click) { set_page! current_page_local - 1 }
        end if current_page_local > 1
      end if pager_start > 1

      ((pager_start)..(pager_end)).each do |p|
        INPUT(defaultValue: current_page_local, className: "btn btn-secondary #{btn_css == 'btn-secondary' ? 'btn-dark' : ''}").
          on(:enter) do |e|
          new_page = e.target.value.to_i
          set_page! new_page if current_page_local != new_page && new_page > 0 && new_page <= number_of_pages
        end if current_page_local == p

        SPAN(className: "btn #{btn_css}") { " #{p} " }.on(:click) { set_page! p } unless current_page_local == p

      end
      begin
        A(className: "btn #{btn_css}") { SPAN(className: "fa fa-forward fa-fw") }.
          on(:click) { set_page! current_page_local + 1 } if current_page_local + 1 <= number_of_pages
        A(className: "btn #{btn_css}") { SPAN(className: "fa fa-fast-forward fa-fw") }.
          on(:click) { set_page! pager_end + 1 } if pager_end + 1 <= number_of_pages
      end if pager_end < number_of_pages

    end if number_of_pages > 1
  end
end