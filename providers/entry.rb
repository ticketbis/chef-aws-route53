include Chef::AwsEc2::Credentials

def whyrun_supported?
  true
end

use_inline_resources

def load_current_resource
  @current_resource = Chef::Resource.resource_for_node(new_resource.declared_type, node).new new_resource.name
  current_resource.client = Chef::AwsEc2.get_route53_client(aws_credentials, aws_region)
  current_resource.zone = get_zone(new_resource.domain.nil? ? new_resource.name : new_resource.name + '.' + new_resource.domain)
  fail "Zone '#{new_resource.domain.nil? ? new_resource.name : new_resource.name + '.' + new_resource.domain}' not found" if current_resource.zone.nil?
  current_resource.entry = get_entry(new_resource.name, new_resource.type)
end

action :create do
  new_entry = {
    name: new_resource.name,
    type: new_resource.type,
    ttl: new_resource.ttl
  }
  new_entry[:resource_records] = new_resource.value.map{|v| {value: v}} unless new_resource.value.nil?
  new_entry[:resource_records] = new_entry[:resource_records].map{|v| {value: "\"#{v[:value]}\""}} if new_resource.type == 'TXT' and new_entry.has_key? :resource_records
  new_entry[:alias_target] = {dns_name: new_resource.alias_to, hosted_zone_id: current_resource.zone.hosted_zone.id, evaluate_target_health: true} unless new_resource.alias_to.nil?
  converge_by "Creating entry '#{new_resource.name}'" do
    changes = []
    if new_resource.type == 'A' or new_resource.type == 'AAAA'
      r = create_request(new_resource.name, 'CNAME')
      changes << {action: 'DELETE', resource_record_set: r} unless r.nil?
    elsif new_resource.type == 'CNAME'
      r = create_request(new_resource.name, 'A')
      changes << {action: 'DELETE', resource_record_set: r} unless r.nil?
      r = create_request(new_resource.name, 'AAAA')
      changes << {action: 'DELETE', resource_record_set: r} unless r.nil?
    end
    current_resource.client.change_resource_record_sets(
      hosted_zone_id: current_resource.zone.hosted_zone.id,
      change_batch: { changes: changes + [{action: 'CREATE', resource_record_set: new_entry}] }
      )
    load_current_resource
  end unless current_resource.exist?
  entry = create_request(current_resource.entry.name, current_resource.entry.type)
  converge_by "Updating entry '#{new_resource.name}'" do
    current_resource.client.change_resource_record_sets(
      hosted_zone_id: current_resource.zone.hosted_zone.id,
      change_batch: { changes: [{action: 'UPSERT', resource_record_set: new_entry}] }
      )
  end if
    entry[:ttl] != new_entry[:ttl] or
    (!entry[:resource_records].nil? and entry[:resource_records].sort{|a,b| a[:value]<=>b[:value]} != new_entry[:resource_records].sort{|a,b| a[:value]<=>b[:value]}) or
    (!entry[:alias_target].nil? and entry[:alias_target].sort{|a,b| a[:dns_name]<=>b[:dns_name]} != new_entry[:alias_target].sort{|a,b| a[:dns_name]<=>b[:dns_name]})
end

action :delete do
  converge_by "Deleting entry '#{new_resource.name}'" do
    entry = create_request(current_resource.entry.name, current_resource.entry.type)
    current_resource.client.change_resource_record_sets(
      hosted_zone_id: current_resource.zone.hosted_zone.id,
      change_batch: {
        changes: [{
          action: 'DELETE',
          resource_record_set: entry
        }]
      }
      )
  end if current_resource.exist?

end

private


def get_zone(rr)
  rr << '.' unless rr.end_with?'.'
  while true
    zone = current_resource.client.list_hosted_zones_by_name(dns_name: rr, max_items: 1).hosted_zones.first
    return current_resource.client.get_hosted_zone(id: zone.id) unless zone.nil? or zone.name != rr
    rr = rr.gsub(/^[^.]+./,'')
    break if rr.empty?
  end
  nil
end

def get_entry(name, type)
  entry = current_resource.client.list_resource_record_sets(
    hosted_zone_id: current_resource.zone.hosted_zone.id,
    start_record_name: name,
    start_record_type: type,
    max_items: 1
    ).resource_record_sets.first
  return nil if entry.nil? or name != entry.name or type != entry.type
  entry
end

def create_request(name,type)
  res = get_entry(name, type)
  return nil if res.nil?
  entry = {
      name: res.name,
      type: res.type,
      ttl: res.ttl
    }
  entry[:resource_records] = res.resource_records.map{|v| {value: v.value}} unless res.resource_records.nil?
  entry[:alias_target] = res.alias_target unless res.alias_target.nil?
  entry
end
