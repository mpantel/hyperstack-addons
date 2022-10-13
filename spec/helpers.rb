module Helpers
  def computed_style(selector, prop)
    page.evaluate_script(
      "window.getComputedStyle(document.querySelector('#{selector}'))['#{prop}']"
    )
  end

  def calculate_window_restrictions
    size_window(100, 100)
    @min_width = width
    size_window(500, 500)
    @height_adjust = 500 - height
    size_window(6000, 6000)
    @max_width = width
    @max_height = height
  end

  def height
    evaluate_script('window.innerHeight')
  end

  def width
    evaluate_script('window.innerWidth')
  end

  def dims
    [width, height]
  end

  def adjusted(width, height)
    [[@max_width, [width, @min_width].max].min, [@max_height, height - @height_adjust].min]
  end

  def click_if_exists(selector, wait: 1)
    if page.has_selector?(selector, wait: wait)
      find(selector).click
    end
  end

  def wait_for_confirm
    wait = Selenium::WebDriver::Wait.new(:timeout => 180)
    wait.until {
      begin
        page.driver.browser.switch_to.alert
        true
        # rescue Selenium::WebDriver::Error::NoAlertPresentError
      rescue Selenium::WebDriver::Error::NoSuchAlertError
        false
      end
    }
  end

  def within_for_browser(selector, firefox:, chrome:)
    within selector.call do
      case page.driver.browser.browser
      when :chrome then chrome.call
      when :firefox then firefox.call
      else
        chrome.call
      end
    end
  end

  def editor_selector(wait: 1)
    selector = "trix-editor.input-sm"
    unless page.has_selector?(selector, wait: wait)
      selector = ".sun-editor-editable"
    end
    selector
  end

  def editor_content(wait: 1)
    find(editor_selector).text
  end

  def fill_editor(wait: 1, text: "", append: false)
    if append
      find(editor_selector).native.send_keys(text)
    else
      find(editor_selector).set(text)
    end
  end

  def set_and_send_tab(selector, index, value)
    all(selector)[case index
                  when :first then 0
                  when :last then -1
                  else
                    index
                  end].then do |control|
      control.set(value)
      control.native.send_keys :tab
    end
  end

end