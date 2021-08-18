name 'Mobile Travel Sample Workshop'
rs_ca_ver 20161221
import "package/common_params", as: "params"
import "package/common_outputs", as: "outs"
import "package/common_resources", as: "res"
import "package/common_definitions", as: "defs"

short_description '
Mobile Workshop'

###########
# Resources
###########
resource 'server', type: 'server' do
    cloud map($region_mapping, $region, "cloud")
    datacenter map($region_mapping, $region, "datacenter")
    subnets "VPC"
    #security_groups map($security_group_mapping, $security_group, "security_group")
    instance_type 'm5.xlarge'
    ssh_key 'Perry_Couchbase'
    server_template find('Couchbase Self-Service Template 5.0', revision: 0)
    cloud_specific_attributes do {
        "automatic_instance_store_mapping" => "true",
        "associate_public_ip_address" => "false",
        "root_volume_type_uid" => "standard"
    } end
end

resource 'group_1', type: 'server', copies: 1 do
    like @server
    name join(["CB Server 7.0.0 and SG 2.7.3 ", copy_index()])
    inputs do {
        'CB_APP_NODE' => 'text:TRUE',
        'CB_SERVER_INSTALL' => 'text:TRUE',
        'CB_SERVER_CLUSTER' => 'text:TRUE',
        'CB_SG_INSTALL' => 'text:TRUE',
        'CB_SG_CLUSTER' => 'text:TRUE',
        'CB_CLUSTERNAME' => join(['text:',first(split(@@deployment.name,"-"))]),
        'CB_CLUSTER_TAG' => join(['text:',last(split(@@deployment.name,"-"))]),
        'CB_REBALANCE_COUNT' => 'text:1',
        'CB_TRAVEL_DEMO' => 'text:TRUE',
    } end
end

resource 'group_2', type: 'server', copies: 3 do
    like @server
    name join(["CB Server 7.0.0 Node ", copy_index()])
    inputs do {
        'CB_SERVER_INSTALL' => 'text:TRUE',
        'CB_CLUSTERNAME' => join(['text:',first(split(@@deployment.name,"-"))]),
        'CB_CLUSTER_TAG' => join(['text:',last(split(@@deployment.name,"-"))]),
        'CB_REBALANCE_COUNT' => 'text:3',
        'CB_SERVER_CLUSTER' => 'text:FALSE',
    } end
end

resource 'group_3', type: 'server', copies: 2 do
    like @server
    name join(["CB SG 2.7.3 Node ", copy_index()])
    inputs do {
        'CB_SERVER_INSTALL' => 'text:FALSE',
        'CB_SG_INSTALL' => 'text:TRUE',
        'CB_SG_CLUSTER' => 'text:FALSE',
        'CB_TRAVEL_DEMO' => 'text:TRUE',
    } end
end

#########
# Parameters
#########

#parameter "workload_override" do
#    type "string"
#    label "Workload Override"
#    max_length 255
#    default "-m 20 -M 20 -I 10000 -t 1 -r 1"
#    operations 'launch'
#end

parameter "region" do
    like $params.region
end
parameter "cluster_port" do
    like $params.cluster_port
end
parameter "sg_port" do
    like $params.sg_port
end
parameter "os" do
    like $params.os
end
parameter "security_group" do
    like $params.security_group
    default "true"
end
parameter "shutdown" do
    like $params.shutdown
    default 600
    min_value 600
    max_value 2160
end


#########
# Mappings
#########

mapping "region_mapping" do
    like $params.region_mapping
end
mapping "os_mapping" do
    like $params.os_mapping
end
mapping "security_group_mapping" do
    like $params.security_group_mapping
end
#########
# Outputs
#########

output "singlenode_server" do
    label "Couchbase Server:"
    category "Develop"
    default_value join(['http://',@group_1.public_ip_address,':',$cluster_port])
end

output "singlenode_sg" do
    label "Couchbase Sync Gateway:"
    category "Develop"
    #default_value join(['http://',@couchbase_sg_nodes.public_ip_address,':4984'])
    default_value join(["http://",@group_1.public_ip_address,":",$sg_port,"/travel-sample"])
end

output_set "secondarycluster" do
    label "Couchbase Cluster:"
    category "Deploy"
    #default_value join(['http://',@group_3.public_ip_address,':',$cluster_port])
    default_value @group_2.public_ip_address
end

output_set "secondary_sg" do
#    label join(["Blank Node ", copy_index()])
    label "Couchbase Sync Gateway"
    category "Deploy"
    default_value @group_3.public_ip_address
end
#output "secondary_sg" do
#    label "Secondary Sync Gateway:"
#    category "Demo"
#    default_value join(['http://',@sg_node.public_ip_address,':4984'])
#end

output "travelapp" do
    label "Travel Application:"
    category "Develop"
    default_value join(['http://',@group_1.public_ip_address,':8080/index.html'])
end

output "guilogin" do
    like $outs.guilogin
    category "Develop"
end
output "sshlogin" do
    like $outs.sshlogin
    category "Develop"
end
output "shutoff" do
    like $outs.shutoff
    category "Develop"
    default_value "This demo will shut down automatically 10 hours after starting."
end

#output_set "primary_nodes" do
##    label join(["Node ", copy_index()])
#    label "Node"
#    category "Primary Cluster Environment"
#    default_value @group_1.public_ip_address
#end
#
#output_set "secondary_nodes" do
##    label join(["Node ", copy_index()])
#    label "Node"
#    category "Secondary Cluster Environment"
#    default_value @group_3.public_ip_address
#end


##########
# Operations
##########

operation 'terminate' do
    like $defs.terminate
end

operation 'enable' do
    like $defs.enable
end

operation 'launch' do
    description 'Launch the application'
    definition 'generated_launch'

    output_mappings do {
        $singlenode_server => join(["http://",$single_node,":", $cluster_port]),
        $singlenode_sg => join(["http://",$single_node,":", $sg_port]),
        $travelapp => join(["http://",$single_node,":8080/index.html"]),
        $secondarycluster => $secondary_cluster_dns,
        $secondary_sg => $sg_dns,
    } end
end

define generated_launch(@server, @group_1, @group_2, @group_3, $cluster_port, $sg_port, $os_mapping, $os, $region, $region_mapping) return $single_node, $sg_dns, $secondary_cluster_dns do

    $single_node =  $sg_dns = $secondary_cluster_dns = []
    $timeout="60m"
    $shutdown=240
    $indexstorage='memopt'

    call defs.validate_port($cluster_port)
    #call defs.get_url($os_mapping, $os, "5.1.0", "") retrieve $cb_url
    $inp = {
        'CB_SHUTDOWN':'text:',
        'CB_INDEX_MODE':join(['text:',$indexstorage]),
        'CB_SERVER_URL':'text:https://packages.couchbase.com/releases/7.0.0/couchbase-server-enterprise-7.0.0-centos7.x86_64.rpm',
        'CB_SG_URL' : 'text:https://packages.couchbase.com/releases/couchbase-sync-gateway/2.7.3/couchbase-sync-gateway-enterprise_2.7.3_x86_64.rpm',
        'CB_UI_PORT':join(['text:',$cluster_port])
    }

    @@deployment.multi_update_inputs(inputs: $inp)

    sub task_label: "Launching Environment:", timeout: $timeout, on_timeout: defs.handle_error("timeout"), on_error: defs.handle_error("") do
        concurrent return $single_node, $sg_dns, $secondary_cluster_dns do
            sub task_label: "Launching Single Nodes:" do
                provision(@group_1)
                @app_nodes = @group_1.get()
                sleep_until( size(@group_1.current_instance().public_dns_names[0]) > 0 )
#                $app_dns = @app_nodes.current_instance().public_dns_names[0]
                $single_node = @group_1.current_instance().public_ip_addresses[0]
            end
            sub task_label: "Launching Secondary Cluster Nodes:" do
                provision(@group_2)
                @group_2 = @group_2.get()
                sleep_until( size(@group_2.current_instance().public_dns_names[0]) > 0 )
#                $secondary_dns = @secondary_cluster_nodes.current_instance().public_dns_names[0]
#$secondary_cluster_dns = @group_3.current_instance().public_ip_addresses[0]

                $secondary_cluster_dns = map @node in @group_2 return $dns do
                    $dns = @node.current_instance().public_dns_names[0]
                end
            end
            sub task_label: "Launching Sync Gateway Nodes:" do
                provision(@group_3)
                @group_3 = @group_3.get()
                sleep_until( size(@group_3.current_instance().public_dns_names[0]) > 0 )
                #                $sg_dns = @couchbase_sg_nodes.current_instance().public_dns_names[0]
                $sg_dns = map @node in @group_3 return $dns do
                    $dns = @node.current_instance().public_dns_names[0]
                end
            end
        end
    end
end
