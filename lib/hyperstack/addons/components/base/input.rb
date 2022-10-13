module Base
  class Input < Base::Component

        param :value
        param :name, default: nil, allow_nil: true
        param :max, default: ''
        param :min, default: ''
        param :placeholder, default: ''
        param :className, default: ''
        param :type, default: :text
        fires :change
        fires :blur
        fires :key_down

    def key
      @key ||= 0
      @key += 1 unless @current_value == value
      @key
    end
  end
end
