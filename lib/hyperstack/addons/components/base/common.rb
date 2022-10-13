module Base
  module Common
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # moved in calls::invitation::edit_in_list
      # def day_in_greek
      #   %w{Κυριακή Δευτέρα Τρίτη Τετάρτη Πέμπτη Παρασκευή Σάββατο}
      # end
      #
      # def month_in_greek
      #   %w{Ιανουαρίου Φεβρουαρίου Μαρτίου Απριλίου Μαΐου Ιουνίου Ιουλίου Αυγούστου Σεπτεμβρίου Οκτωβρίου Νοεμβρίου Δεκεμβρίου}
      # end
      #
      # def display_long_greek_date(date)
      #   return '' unless date.blank?
      #   [day_in_greek[date.wday],', ',date.day,' ',month_in_greek[date.month - 1],' ', date.year].join
      # end

      def emoji_flag(country_code)
        # https://andycroll.com/ruby/convert-iso-country-code-to-emoji-flag/
        cc = country_code.to_s.upcase
        return unless cc =~ /\A[A-Z]{2}\z/

        cc.codepoints.map { |c| (c + 127397).chr(Encoding::UTF_8) }.join
      end

      def display_currency(currency)
        ("%.2f" % currency).tr('.', ',').reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse
      end

      def display_date(date, show_time = false)
        begin
          parsed_date = Time.parse(date) #.utc
          parsed_date.strftime('%d/%m/%Y' + (show_time ? ' %H:%M' : ''))
        rescue
          ''
        end if date && date.loaded?
      end

      def escape_characters_in_string(string)
        pattern = /(\'|\"|\.|\*|\/|\-|\\|\)|\$|\+|\(|\^|\?|\!|\~|\`)/
        string.gsub(pattern) { |match| "\\" + match }
      end

      # def display_date(date, show_time = false)
      #   begin
      #     parsed_date = Time.parse(date)
      #     if show_time
      #       parsed_date.strftime('%d/%m/%Y %H:%M')
      #     else
      #       parsed_date.strftime('%d/%m/%Y')
      #     end
      #   end if date  && date.loaded?
      # end
    end

    def strip_html(value)
      value&.gsub(/<("[^"]*"|'[^']*'|[^'">])*>/, '')&.gsub(/&nbsp;/, ' ')
    end

    def escape_characters_in_string(string)
      self.class.escape_characters_in_string(string)
    end

    def display_currency(currency)
      self.class.display_currency(currency)
    end

    def display_date(date, show_time = false)
      self.class.display_date(date, show_time)
    end

    def t(attribute, opts = {}, klass = self.class, initial_class_name = nil)
      return attribute unless Object.const_defined?("Translator")
      return attribute if Translator.locale == 'el'

      namespace = klass.name.underscore.gsub(%r{::|/}, '.')
      attribute = attribute.gsub(%r{\.}, '_')
      temp = Hyperstack::Internal::I18n.t("#{namespace}.#{attribute}", opts)

      i_c_n = initial_class_name || namespace
      if temp =~ /translation missing:/
        if !%w[Base::Component Base::ComponentRouter].include?(klass.name)
          t(attribute, opts, klass.superclass, i_c_n)
        else
          Translator.fill_translations(i_c_n, attribute)
          attribute
        end
      else
        Translator.fill_translations(namespace, attribute)
        temp
      end
    end

  end
end