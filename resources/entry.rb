actions :create, :delete

default_action :create

attribute :name, kind_of: String, name_attribute: true
attribute :type, kind_of: String, equal_to: ['A', 'AAAA', 'CNAME', 'TXT', 'SPF'], default: 'A', required: true
attribute :ttl, kind_of: Integer, default: 300, required: true, callbacks: {
  "TTL must be positive" => lambda {|x| x > 0}
}
attribute :domain, kind_of: String
attribute :value, kind_of: [String, Array]
attribute :alias_to, kind_of: String
attribute :region, kind_of: String
attribute :access_key_id, kind_of: String
attribute :secret_access_key, kind_of: String

attr_accessor :client, :zone, :entry

def exist?
  !entry.nil?
end

def after_created
  value [@value] if @value.instance_of? String
end

