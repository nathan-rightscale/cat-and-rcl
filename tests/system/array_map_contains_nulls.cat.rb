#test:desired_state=running

name "array_map_contains_nulls"
rs_ca_ver 20131202
short_description "This is not an empty string"

operation "launch" do
  description "Do the stuff"
  definition "launch"
end

define log($message, $notify) do
  rs.audit_entries.create(notify: $notify, audit_entry: {auditee_href: @@deployment.href, summary: $message})
end

define launch() do
  $source = [1,2,3,4]
  $result = concurrent map $num in $source return $foo do
    if $num == 1
      $foo = $num
    end
  end

  $size = size($result)
  if $size != 1
    call log("Result of concurrent map on array"+to_json($result),"None")
    raise "Result has "+$size+" items, but expected only 1"
  end
end
