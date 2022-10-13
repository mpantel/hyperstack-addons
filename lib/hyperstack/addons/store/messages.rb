class Messages
  include Hyperstack::State::Observable

  class << self

    observer(:message_hash) { @message_hash || {} }

    def add_message(msg, component, new_message_key = '')
      @message_hash = {} unless @message_hash
      @message_hash[component] = {} unless @message_hash[component]
      new_message_key = `Math.floor(Math.random() * 1000000)`.to_s if new_message_key.blank?
      mutate @message_hash[component][new_message_key] = msg if @message_hash[component][new_message_key].blank?
    end

    def clear_message(component, message_key)
      @message_hash[component].delete(message_key)
    end

    def clear_all_messages
      mutate @message_hash = {}
    end

  end

end