class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  # allow remote access to all scopes - i.e. you can count or get a list of ids
  # for any scope or relationship

  # regulate_scope all: -> { acting_user if acting_user.is_a? ::User }
  # #regulate_scope apply_filter: -> { acting_user if acting_user.is_a?(::User) || acting_user.is_a?(GuestUser) }
  # regulate_scope unscoped: -> { acting_user if acting_user.is_a? ::User }
  # regulate_scope limit: -> { acting_user if acting_user.is_a? ::User }
  # regulate_scope offset: -> { acting_user if acting_user.is_a? ::User }

  #hypermodel_compatibility_mode = :strict #:warning # or :strict, :ignore

  scope :limitter,
        server: ->(offset, limit) { offset(offset).limit(limit) }
  scope :apply_filter,
        server: -> (filters) {
          if filters.blank?
            self
          else
            filters.#reject { |f, v| v.blank? }.
            inject(self) do |result, (filter, value)|
              result.send(filter.to_sym, value)
            end
          end #.all
        }
  scope :sorting,
        server: -> (sorting_hash) {
          if sorting_hash.blank? #.select{|k,v| attribute_names.include?(k.to_s)}.blank?
            self
          else
            self.reorder(sorting_hash) #.map{|k,v|[k.to_s=='id' ? self.primary_key : k, v]}.to_h)
          end #.all

        } #,

  ApplicationRecord.regulate_scope :all unless Hyperstack.env.production?
end
