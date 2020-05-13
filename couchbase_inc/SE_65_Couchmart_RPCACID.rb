name '6.5 Retail Demo - ACID Transactions'
rs_ca_ver 20161221
import "package/se_common", as: "import"


short_description '
**Contains RPC service implementing ACID transactions**

**Updated with Sync Gateway 2.7.0**

**Updated with Couchbase Server 6.5.0**

Based on Couchmart demo: https://github.com/couchbaselabs/connect-eu-demo
Video recording of the demo: https://youtu.be/wzYBILeksU4

This demo aims to mimick the same functionality as the standard Couchmart demo whilst using the ACID transactions feature introduced in 6.5. 

There is an added intermediary service, installed on the app node, which handles requests from the app server and forms an ACID request to CB server. 

This service is named POSTY, it will determine whether there is enough stock of the requested items, decrementing stock and placing an order if all items are available.

A demo enviornment with:
- 2 clusters (to showcase XDCR), one with MDS
- A Couchmart bucket loaded and workload running.
- Sync Gateway deployed against primary cluster.

Click details for more information

**Note: shuts down after 4 hours**
'

long_description '
Standard Demo includes:
- 1 Primary Cluster:
 - 3 data nodes
- 2 blank nodes to be added
- 1 Secondary Cluster (to be manually linked via XDCR):
 - 3 nodes with all services enabled
 - 1 Sync Gateway
- 1 Application Server running Couchmart application, RPC ACID service, and synthetic workload
 - Override workload with "-h"
'

###########
# Resources
###########

resource 'app_nodes', type: 'server', copies: 1 do
    like @import.acidapp
    name join(["App Node ", copy_index()])
    inputs do {
        'CB_APP_NODE' => 'text:TRUE',
        'CB_WAIT_FOR_CLUSTER' => 'text:TRUE',
        'CB_QUERY_LOAD' => 'text:TRUE',
        'CB_KV_LOAD' => 'text:TRUE',
        'CB_ACID_DEMO' => 'text:TRUE',
        'CB_WORKLOAD_OVERRIDE' => join(['text:',$workload_override])
    } end
end

resource 'sg_nodes', type: 'server', copies: 1 do
    like @import.server
    name join(["CB Sync Gateway 2.7.0 ", copy_index()])
    inputs do {
        'CB_APP_NODE' => 'text:FALSE',
        'CB_SG_INSTALL' => 'text:TRUE',
        'CB_SG_CLUSTER' => 'text:TRUE',
        'CB_WAIT_FOR_CLUSTER' => 'text:TRUE'
    } end
end

resource 'blank_nodes', type: 'server', copies: 2 do
    like @import.server
    name join(["CB Server 6.5.0 Blank Node ", copy_index()])
    inputs do {
        'CB_APP_NODE' => 'text:FALSE',
        'CB_SG_INSTALL' => 'text:FALSE',
        'CB_SERVER_INSTALL' => 'text:TRUE',
        'CB_SERVER_CLUSTER' => 'text:FALSE'
    } end
end

resource 'primary_cluster_data_nodes', type: 'server', copies: 3 do
    like @import.server
    name join(["CB Server 6.5.0 Primary Cluster Data Node ", copy_index()])
    inputs do {
        'CB_APP_NODE' => 'text:FALSE',
        'CB_SG_INSTALL' => 'text:FALSE',
        'CB_SERVER_INSTALL' => 'text:TRUE',
        'CB_CLUSTERNAME' => join(['text:',first(split(@@deployment.name,"-"))]),
        'CB_REBALANCE_COUNT' => 'text:3',
        'CB_SERVICES' => 'text:data',
        'CB_SERVER_CLUSTER' => 'text:TRUE'
    } end
end

resource 'secondary_cluster_nodes', type: 'server', copies: 3 do
    like @import.server
    name join(["CB Server 6.5.0 Secondary Cluster Node ", copy_index()])
    inputs do {
        'CB_APP_NODE' => 'text:FALSE',
        'CB_SG_INSTALL' => 'text:FALSE',
        'CB_SERVER_INSTALL' => 'text:TRUE',
        'CB_SERVICES' => 'text:data,query,index,fts',
        'CB_CLUSTERNAME' => join(['text:',first(split(@@deployment.name,"-")),"-Secondary"]),
        'CB_CLUSTER_TAG' => join(['text:',last(split(@@deployment.name,"-")),"-Secondary"]),
        'CB_REBALANCE_COUNT' => 'text:3',
        'CB_SERVER_CLUSTER' => 'text:TRUE'
    } end
end

#########
# Parameters
#########

parameter "workload_override" do
    type "string"
    label "Workload Override"
    max_length 255
    default "-m 20 -M 20 -I 10000 -t 1 -r 10 --rate-limit 1000"
    operations 'launch'
end

parameter "region" do
    like $import.region
end
parameter "cluster_port" do
    like $import.cluster_port
end
parameter "sg_port" do
    like $import.sg_port
end
parameter "os" do
    like $import.os
    allowed_values "CentOS/RHEL 7.x"
end
parameter "security_group" do
    like $import.security_group
end
parameter "shutdown" do
    like $import.shutdown
    max_value 480
end


#########
# Mappings
#########

mapping "region_mapping" do
    like $import.region_mapping
end
mapping "os_mapping" do
    like $import.os_mapping
end
mapping "security_group_mapping" do
    like $import.security_group_mapping
end
#########
# Outputs
#########

output "primarycluster" do
    label "Primary Couchbase Cluster:"
    category "Demo"
    default_value join(['http://',@primary_cluster_data_nodes.public_ip_address,':',$cluster_port])
end

output "primary_sg" do
    label "Sync Gateway:"
    category "Demo"
    default_value join(["http://",@sg_nodes.public_ip_address,":4984/couchmart (user 'admin', password 'password')"])
end

output "secondarycluster" do
    label "Secondary Couchbase Cluster:"
    category "Demo"
    default_value join(['http://',@secondary_cluster_nodes.public_ip_address,':',$cluster_port])
end

output_set "blank_nodes" do
    label "Node"
    category "Blank Nodes"
    default_value @blank_nodes.public_ip_address
end

output "travelapp" do
    label "CouchMart Application:"
    category "Demo"
    default_value join(['http://',@app_nodes.public_ip_address,':8080'])
end

output "guilogin" do
    like $import.guilogin
end
output "sshlogin" do
    like $import.sshlogin
end
output "shutoff" do
    like $import.shutoff
end

output_set "primary_nodes" do
#    label join(["Node ", copy_index()])
    label "Node"
    category "Primary Cluster Environment"
    default_value @primary_cluster_data_nodes.public_ip_address
end

output_set "secondary_nodes" do
#    label join(["Node ", copy_index()])
    label "Node"
    category "Secondary Cluster Environment"
    default_value @secondary_cluster_nodes.public_ip_address
end


##########
# Operations
##########

operation 'terminate' do
    like $import.terminate
end

operation 'enable' do
    like $import.enable
end

operation 'launch' do
    description 'Launch the application'
    definition 'generated_launch'

    output_mappings do {
        $primarycluster => join(["http://",$primary_ip,":", $cluster_port]),
        $secondarycluster => join(["http://",$secondary_ip,":", $cluster_port]),
        $travelapp => join(["http://",$app_ip,":8080"]),
        $primary_sg => join(["http://",$sg_ip,":4984/couchmart (user 'admin', password 'password')"]),
        $blank_nodes => $blank_dns,
        $primary_nodes => $primary_nodes_dns,
        $secondary_nodes => $secondary_nodes_dns,
    } end
end

define generated_launch(@app_nodes, @blank_nodes, @primary_cluster_data_nodes, @secondary_cluster_nodes, @sg_nodes, $cluster_port, $sg_port, $os_mapping, $os, $region, $region_mapping) return $app_ip, $blank_dns, $sg_ip, $primary_ip, $secondary_ip, $primary_nodes_dns, $secondary_nodes_dns on_error: import.handle_error("Launch Failed:"), timeout: 30m, on_timeout: import.handle_timeout("Launch Timeout") do

    $app_dns = $blank_dns = $sg_dns = $primary_dns = $secondary_dns = $primary_nodes_dns = $secondary_nodes_dns = []
    $shutdown=240
    $indexstorage='memopt'

    call import.validate_port($cluster_port)
    call import.get_url($os_mapping, $os, "6.5.0", "") retrieve $cb_url

    $cb_url = "http://nas.service.couchbase.com/builds/latestbuilds/couchbase-server/mad-hatter/6226/couchbase-server-enterprise-6.5.1-6226-centos7.x86_64.rpm"
    $sg_url = "https://packages.couchbase.com/releases/couchbase-sync-gateway/2.7.0/couchbase-sync-gateway-enterprise_2.7.0_x86_64.rpm"
    $inp = {
        'CB_SHUTDOWN':'text:',
        'CB_INDEX_MODE':join(['text:',$indexstorage]),
        'CB_SERVER_URL':join(['text:',$cb_url]),
        'CB_SG_URL' :join(['text:',$sg_url]),
        'CB_UI_PORT':join(['text:',$cluster_port]),
        'CB_BUCKET' : 'text:couchmart',
        'CB_COUCHMART_DEMO' : 'text:TRUE',
        'CB_TRAVEL_DEMO' : 'text:FALSE',
        'CB_CLUSTER_TAG' : join(['text:',last(split(@@deployment.name,"-"))])
    }

    @@deployment.multi_update_inputs(inputs: $inp)

    call import.log("Concurrently Launching Nodes")

    concurrent return $app_ips, $blank_dns, $sg_ips, $secondary_nodes_dns, $secondary_nodes_ips, $data_dns, $data_ips task_label: "Launching Demo Environment", on_error: import.handle_error("Concurrent Launch Failed:") do

        call launch_nodes_ip_dns("App Nodes",@app_nodes) retrieve $app_ips, $app_dns
        call launch_nodes_ip_dns("Blank Nodes", @blank_nodes) retrieve $blank_ips, $blank_dns
        call launch_nodes_ip_dns("SG Nodes", @sg_nodes) retrieve $sg_ips, $sg_dns
        call launch_nodes_ip_dns("Secondary Cluster Nodes", @secondary_cluster_nodes) retrieve $secondary_nodes_ips, $secondary_nodes_dns

        concurrent return $data_dns, $data_ips task_label: "Primary Cluster", on_error: import.handle_error("Concurrent Group Launch Failed:") do
            call launch_nodes_ip_dns("Primary Cluster Data Nodes", @primary_cluster_data_nodes) retrieve $data_ips, $data_dns
        end
    end

    $app_ip = $app_ips[0]
    $sg_ip = $sg_ips[0]
    $primary_ip = $data_ips[0]
    $primary_nodes_dns = $data_dns
    $secondary_ip = $secondary_nodes_ips[0]

    call import.log("Finished Launching CloudApp")
end

define launch_nodes_ip_dns($name, @nodes) return $ips_return, $dns_return task_label: "Launching "+$name+ ":", on_error: import.handle_error("Launch "+$name+" failed") do
    call import.log("Launching "+$name)
    provision(@nodes)
    @nodes = @nodes.get()

    sleep_until( size(@nodes.current_instance().public_ip_addresses[0]) > 0 )
    sleep_until( size(@nodes.current_instance().public_dns_names[0]) > 0 )

    $dns_return = map @node in @nodes return $dns do
        $dns = @node.current_instance().public_dns_names[0]
    end

    $ips_return = map @node in @nodes return $ips do
        $ips = @node.current_instance().public_ip_addresses[0]
    end
    call import.log("Launched " + to_s($name)+"\nDNS: " + to_s($dns_return)+", IPs: "+ to_s($ips_return))
end
