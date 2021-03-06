name "terminator"
rs_ca_ver 20131202
short_description "Find old stuff, delete it.. Save money.."

parameter "instances_hours_old_param" do
  type "number"
  label "Instance Age in hours"
  default 24
end

parameter "skip_tag_param" do
  type "string"
  label "Tag, which if applied to a resource will instruct the terminator to spare that resource"
  default "terminator:skip=true"
end

operation "launch" do
  description "Do the stuff"
  definition "terminator"
end

#include:../definitions/sys.cat.rb

#include:../definitions/tag.cat.rb

define terminator($instances_hours_old_param,$skip_tag_param) do
  concurrent do
    sub task_name:"instances" do
      concurrent foreach @cloud in rs.clouds.get() do
        concurrent foreach @instance in @cloud.instances(filter: ["state<>inactive","state<>terminated"]) do
          $instances_hours_old_seconds = (to_n($instances_hours_old_param)*60)*60
          call get_tags_for_resource(@instance) retrieve $tags
          if type($tags) == "null"
            $tags = []
          end
          $created_at = to_n(@instance.created_at)
          $created_delta = to_n(now()) - $created_at

          $is_old_enough = $created_delta > $instances_hours_old_seconds
          $is_not_tagged = logic_not(contains?($tags, [$skip_tag_param]))
          if $is_old_enough & $is_not_tagged
            call sys_log("Would terminate "+@instance.name+" because it is older than "+$instances_hours_old_seconds+" seconds, and is not tagged with "+$skip_tag_param,{})
          else
            call sys_log("Leaving "+@instance.name+" alone because it is not older than "+$instances_hours_old_seconds+" seconds, or is tagged with "+$skip_tag_param,{})
          end
        end
      end
    end

    sub task_name:"volumes" do
      call sys_get_clouds_by_rel("volumes") retrieve @clouds
      call sys_log("Clouds with volume support is "+size(@clouds),{})
    end

    sub task_name:"snapshots" do
      #call get_clouds_by_rel("volume_snapshots") retrieve @clouds
    end

    sub task_name:"ips" do

    end

    sub task_name:"ssh_keys" do

    end

    # sub task_name:"server_templates" do
    #
    # end

    # sub task_name:"Services? ELB, RDS, Other stuff?" do
    #
    # end
  end
end
