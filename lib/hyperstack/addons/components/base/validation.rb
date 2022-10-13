require 'time'

module Base
  class Validation

    def initialize(columns:, data_object:)
      @columns = columns #.each {|k,v| v.merge!({errors:[]}) }
      @data_object = data_object
      @current_field = nil
      @error_messages = @columns.inject({}) { |m, (k, v)| m.merge!({ k => [] }) } #{}
      @error_reporting_methods = [:alert] #[:alert,:render,:inline]
      @custom_msg = nil
      @on_error = :nihilize
      @warnings = []
      @nil_value = nil
    end

    def initialize_error_messages
      @error_messages = @columns.inject({}) { |m, (k, v)| m.merge!({ k => [] }) }
      @warnings = []
    end

    def set_current_field(field)
      @current_field = field
    end

    def validate(field: nil)
      if field
        validate_field(field: field)
      else
        @columns.each do |key, content|
          validate_field(field: key)
        end
      end
      count_errors == 0
    end

    def validate_field(field:)
      set_current_field(field)
      @move_on = true
      @nil_value = @columns[@current_field][:validation_nil_value]
      @columns[@current_field][:validation].each do |meth|
        return unless @error_messages[@current_field].blank?
        return if ((!@columns[@current_field][:validation].map { |i| i.is_a?(Hash) ? i.keys.first : i }.include?(:required) || !@move_on) && @data_object[@current_field].blank?)
        if meth.is_a?(Symbol)
          self.send(meth)
        elsif meth.is_a?(Hash) #else
          params = meth.first[1]
          @on_error = params[:on_error] if params[:on_error]
          @custom_msg = params[:custom_msg].blank? ? nil : params[:custom_msg]
          (self.method(meth.first[0].to_sym).arity == 0) ? self.send(meth.first[0]) : self.send(meth.first[0], params)
        end
      end
    end

    def count_errors
      @error_messages.inject(0) { |m, (k, v)| m + v.length } #[:errors]
    end

    def get_errors
      @error_messages
    end

    def get_errors_flattened
      @error_messages.values.flatten.map { |i| "- #{i}" }
    end

    def final_msg(msg)
      final = @custom_msg.blank? ? msg : @custom_msg
      @custom_msg = nil
      final
    end

    def append_error(msg)
      @error_messages[@current_field] << final_msg(msg)
    end

    def show_errors
      alert @error_messages.values.flatten.uniq.map { |i| "- #{i}" }.join("\n")
      initialize_error_messages
    end

    def nihilize
      @data_object[@current_field] = @nil_value
    end

    def append_error_and_nihilize(msg, nil_value = nil)
      if @on_error == :nihilize
        append_error(msg)
        nihilize
      else
        if @on_error == :warning
          @warnings << final_msg(msg)
        end
        @on_error = :nihilize
      end
    end

    def return_warnings
      w = @warnings
      @warnings = []
      w
    end

    #################  VALIDATION METHODS #################

    def valid?(afm)
      #9 chars, string

      @afm = afm.to_s
      return false if @afm.length != 9 # length == 9
      return false if (@afm =~ /\A[\d]+\z/).nil? # only digits  (@afm =~ /\A[\d\s,-]+\z/).nil?
      return false if @afm.to_i == 0 # do not allow all digits zero
      y = @afm[-1].to_i # rest / ninth digit
      s = 0 # runnning sum
      pow2 = 2 # 2 power cache
      7.downto(0) do |i|
        s += pow2 * @afm[i].to_i
        pow2 = pow2 * 2
      end
      s = s % 11
      s = 0 if s == 10
      s == y
    end

    def valid_afm(country_field: nil, country_field_key: nil, greece_value: "Ελλάδα")
      check_afm = if country_field.nil? # || (!country_field.nil? && country_field_key.nil?)
                    true
                  else
                    value = (country_field_key.nil? ? @data_object[country_field] : JSON.parse(@data_object[country_field])[country_field_key])
                    value.to_s == greece_value.to_s
                  end
      append_error_and_nihilize("Η τιμή στο πεδίο #{@columns[@current_field][:description]} δεν ανήκει σε σωστό τύπο ΑΦΜ."
      ) if check_afm && !valid?(@data_object[@current_field].to_s.strip)
    end

    def compare_with(key: nil, value: nil, comparison: "==", plus: nil, equality: true)
      final_value = if key
                      value || @data_object[key]
                    else
                      value
                    end
      final_value += plus if plus

      msg = "Το πεδίο #{@columns[@current_field][:description]} πρέπει να έχει τιμή #{comparisons_verbal[comparison]} #{key ? "την τιμή στο πεδίο: #{@columns[key][:description]}" : "#{value}"}"

      append_error_and_nihilize(msg) unless comparisons(@data_object[@current_field].is_a?(String) ? @data_object[@current_field].strip : @data_object[@current_field], final_value, comparison)
    end

    def comparisons_verbal
      {
        ">": "μεγαλύτερη από",
        ">=": "μεγαλύτερη από ή ίση με",
        "<": "μικρότερη από",
        "<=": "μικρότερη από ή ίση με",
        "==": "ίση με",
        "!=": "διαφορετική από",
      }
    end

    def comparisons(value1, value2, comparison, reverse = false)
      first_value, second_value = (reverse ? [value2, value1] : [value1, value2])
      return unless first_value.respond_to?(comparison.to_sym)
      first_value.send(comparison.to_s, second_value)
    end

    # def in_db(data_class:, nihilize: true)
    #   msg = "Η τιμή στο πεδίο #{@columns[@current_field][:description]} είναι ήδη καταχωρημένη."
    #   # obj=data_class.constantize.find_by(@current_field.to_sym => @data_object[@current_field])
    #   FieldValueExists.run(data_class: data_class, field_value_hash: {@current_field.to_sym => @data_object[@current_field].to_s.strip}).then do |exists|
    #     if exists
    #       nihilize ? append_error_and_nihilize(msg) : append_error(msg)
    #     end
    #   end
    #   # unless obj.nil? || obj.id.to_s=='0'
    #   #   nihilize ? append_error_and_nihilize(msg) : append_error(msg)
    #   # end
    # end

    def json_validation(columns:, current_value_is_json: true)
      data_object = (current_value_is_json ? JSON.parse(@data_object[@current_field]) : @data_object[@current_field])
      #???? if @data_object[@current_field] blank? ?????
      val = Base::Validation.new(columns: columns, data_object: data_object)
      unless val.validate
        @data_object[@current_field] = (current_value_is_json ? data_object.to_json : data_object)
        @error_messages.merge!(val.get_errors)
      end
      @warnings += val.return_warnings
    end

    def array_validation(columns:, current_value_is_json: true)
      data_object = (current_value_is_json ? JSON.parse(@data_object[@current_field]) : @data_object[@current_field])
      error_messages = {}
      data_object.each_with_index do |value, index|
        value_object = { columns.first[0] => value }
        val = Base::Validation.new(columns: columns, data_object: value_object)
        unless val.validate
          data_object[index] = value_object[columns.first[0]]
          error_messages.merge!(val.get_errors.map { |k, v| ["#{k.to_s}_#{index}".to_sym, (v.blank? ? v : "#{columns.first[1][:description]} νο #{index + 1}: #{v}")] }.to_h)
          # ------> TODO ------> @warnings += val.return_warnings
        end
      end
      @data_object[@current_field] = (current_value_is_json ? data_object.to_json : data_object)
      @error_messages.merge!(error_messages)
    end

    def required
      return unless @move_on
      append_error_and_nihilize("Στο πεδίο #{@columns[@current_field][:description]} δεν μπορεί να υπάρχει κενή τιμή/επιλογή."
      ) if @data_object[@current_field].blank?
    end

    def depends_on_other_fields(other_fields: {}, how_to_compare: "==", reverse: false)
      other_fields.each do |field, value|
        @move_on = @move_on && comparisons(@data_object[field], value, how_to_compare, reverse)
      end
    end

    def valid_email
      append_error_and_nihilize("Το email στο πεδίο #{@columns[@current_field][:description]} δεν είναι σωστό."
      ) if (@data_object[@current_field].to_s.strip =~ /\A[a-zA-Z0-9.!\#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+\z/).nil? #URI::MailTo::EMAIL_REGEXP
    end

    def valid_greek_or_english_name
      append_error_and_nihilize("Το πεδίο #{@columns[@current_field][:description]} μπορεί να έχει μόνο γράμματα του ελληνικού και του αγγλικού αλφαβήτου και τον χαρακτήρα (-)."
      ) if (@data_object[@current_field].to_s.strip =~ /\A[a-zA-Z\u0370-\u03ff\u1f00-\u1fff\s-]+\z/u).nil?
    end

    def phone_format
      append_error_and_nihilize("Το πεδίο #{@columns[@current_field][:description]} μπορεί να έχει μόνο αριθμούς και τους χαρακτήρες [-],[,],[+],[ ]."
      ) if (@data_object[@current_field].to_s.strip =~ /\A[\+\d\s,-]+\z/).nil?
    end

    def min_length(min:)
      append_error_and_nihilize("Η τιμή στο πεδίο #{@columns[@current_field][:description]} πρέπει να έχει ελάχιστο μήκος #{min} χαρακτήρες."
      ) if @data_object[@current_field].to_s.strip.length < min.to_i
    end

    def max_length(max:)
      append_error_and_nihilize("Η τιμή στο πεδίο #{@columns[@current_field][:description]} πρέπει να έχει μέγιστο μήκος #{max} χαρακτήρες."
      ) if @data_object[@current_field].to_s.strip.length > max.to_i
    end

    def min_max_length(min:, max:)
      append_error_and_nihilize("Η τιμή στο πεδίο #{@columns[@current_field][:description]} πρέπει να έχει μήκος #{min == max ? "ακριβως #{max} χαρακτήρες" : "από #{min} έως #{max} χαρακτήρες"}."
      ) unless @data_object[@current_field].to_s.strip.length.between?(min.to_i, max.to_i)
    end

    def date_formats_regex
      {
        '%d/%m/%Y' => /[0-3][0-9]\/[0-1][0-9]\/[0-9]{2}(?:[0-9]{2})?/
      }
    end

    def valid_date(date_format: '%d/%m/%Y')
      append_error_and_nihilize("Η τιμή στο πεδίο #{@columns[@current_field][:description]} δεν έχει σωστό τύπο ημερομηνίας: #{date_format}."
      ) unless @data_object[@current_field].strip.match(date_formats_regex[date_format])
    end

    def acceptable_value(values:)
      if values.is_a?(Hash)
        values = ActiveSupport::HashWithIndifferentAccess.new(values)
        is_acceptable = !values[@data_object[@current_field]].nil?
        acceptable_values = values.values.join(", ")
      elsif values.is_a?(Array)
        is_acceptable = values.include?(@data_object[@current_field])
        acceptable_values = values.join(", ")
      end
      append_error_and_nihilize("Η τιμή στο πεδίο #{@columns[@current_field][:description]} δεν ανήκει στις αποδεκτές τιμές: #{acceptable_values}.") unless is_acceptable
    end

    def valid_type(type: :integer)
      append_error_and_nihilize("Η τιμή στο πεδίο #{@columns[@current_field][:description]} πρέπει να είναι #{value_types[type.to_sym][:verbal]}.") unless @data_object[@current_field].is_a?(value_types[type.to_sym][:class])
    end

    def value_types
      {
        string: {
          class: String,
          verbal: "κείμενο"
        },
        integer: {
          class: Integer,
          verbal: "ακέραιος"
        },
        float: {
          class: Float,
          verbal: "δεκαδικός"
        },
      }
    end

    def execute_proc(proc:)
      append_error_and_nihilize("Η τιμή στο πεδίο #{@columns[@current_field][:description]} πρέπει να proc.") unless proc.call(@data_object[@current_field])
    end

    #################  VALIDATION METHODS #################

    EXAMPLE_DATA_OBJECT = {
      submission_metadata: { description: ' ΤΟ ΠΕΔΙΟ ΤΟΥ ΠΙΝΑΚΑ', usage: :w, format: :json, validation: [:required, { json_validation: { columns: {
        proposal_type: { description: 'ΕΝΑ ΑΠΛΟ ΚΛΕΙΔΙ ΠΟΥ ΕΧΕΙ ΤΙΜΗ', validation: [:required] },
        contact: { description: 'ΕΝΑ ΣΥΝΘΕΤΟ ΚΛΕΙΔΙ ΠΟΥ ΕΧΕΙ ΩΣ ΤΙΜΗ ΕΝΑ ΑΛΛΟ HASH', validation: [
          { json_validation: { columns: {
            financier: { description: 'ΚΛΕΙΔΙ ΤΟΥ ΣΥΝΘΕΤΟΥ ΚΛΕΙΔΙΟΥ 1', validation: [:required, { min_max_length: { min: 2, max: 300 } }] },
            total_budget: { description: 'ΚΛΕΙΔΙ ΤΟΥ ΣΥΝΘΕΤΟΥ ΚΛΕΙΔΙΟΥ 2', validation: [:required, { min_max_length: { min: 2, max: 300 } }] },
            aegean_budget: { description: '3', validation: [:required, { min_max_length: { min: 2, max: 300 } }] }
          },
                               current_value_is_json: false } }
        ]
        },
      }
      } }] },
    }

  end
end
