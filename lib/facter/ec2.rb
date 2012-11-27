require 'net/http'
require 'facter'

EC2_METADATA_URL="http://169.254.169.254/latest/meta-data/"
http = Net::HTTP.new(uri.host)

# Issue an HTTP Get to the metadata service and yield the block if get is successful
def http_get(request_uri)
  response = http.get(Net::HTTP::Get.new(uri.request_uri + item_name))
  yield response.body if response.code == "200"
end

def fact_from_metadata_item(item_name, fact_name=nil)
  http_get(uri.request_uri + item_name) do |response|
    fact_name = item_name.tr("-/", "__") if fact_name.nil?
    Facter.add("ec2_" + fact_name) do
      setcode do
        response
      end
    end
  end
end

def fact_from_metadata_collection(collection_name)
  http_get(uri.request_uri + collection_name) do |response|
    response.lines.each do |item|
      fact_from_metadata_item(collection_name + "/" + item)
    end
  end
end

%w( ami-id ami-launch-index ami-manifest-path instance-id instance-type kernel-id 
  local-hostname local-ipv4 mac public-hostname public-ipv4 ramdisk-id
  reservation-id security-groups
).each do |item|
  fact_from_metadata_item(item)
end

fact_from_metadata_item("placement/availability-zone", "availability_zone")
fact_from_metadata_collection("block_device_mapping")
