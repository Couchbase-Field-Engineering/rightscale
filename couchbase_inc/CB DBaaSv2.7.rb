
name 'CB DBaaSv2.7'
rs_ca_ver 20161221
import "package/se_common", as: "import"

short_description 'Instructions available [here](http://hub.internal.couchbase.com/confluence/download/attachments/19508199/CBDBaaSInstructions.pdf?version=2&modificationDate=1479988082000&api=v2)

Flexible cluster configuration for POC environments:
- One cluster (with/without MDS)
- "Blank" nodes (CB installed, not clustered)
- App servers w/ ycsb, Java, libcouchbase, etc.
- Click **Details** for more information

To work with multiple clusters, simply launch multiple of these environments.

Build URLs ([Currently active releases](https://hub.internal.couchbase.com/confluence/display/PM/Couchbase+Server)):
- [4.x](http://couchbase:YAN3FrT7k@nas.service.couchbase.com/builds/latestbuilds/couchbase-server/watson/?C=N;O=D)
- [5.0.x](http://couchbase:YAN3FrT7k@nas.service.couchbase.com/builds/latestbuilds/couchbase-server/spock/?C=N;O=D)
- [5.5.x](http://couchbase:YAN3FrT7k@nas.service.couchbase.com/builds/latestbuilds/couchbase-server/vulcan/?C=N;O=D)
- [6.x](http://couchbase:YAN3FrT7k@nas.service.couchbase.com/builds/latestbuilds/couchbase-server/alice/?C=N;O=D)
- [6.5.x](http://couchbase:YAN3FrT7k@nas.service.couchbase.com/builds/latestbuilds/couchbase-server/mad-hatter/?C=N;O=D)
- [6.6.x](http://couchbase:YAN3FrT7k@nas.service.couchbase.com/builds/latestbuilds/couchbase-server/mad-hatter/?C=N;O=D)
- [Cheshire-Cat](http://couchbase:YAN3FrT7k@nas.service.couchbase.com/builds/latestbuilds/couchbase-server/cheshire-cat/?C=N;O=D)
'

long_description 'Instructions available [here](http://hub.internal.couchbase.com/confluence/download/attachments/19508199/CBDBaaSInstructions.pdf?version=2&modificationDate=1479988082000&api=v2)

Choose:
- Build URLs ([Currently active releases](http://hub.internal.couchbase.com/confluence/display/PM/Active+Releases)):
- [4.x](http://couchbase:YAN3FrT7k@nas.service.couchbase.com/builds/latestbuilds/couchbase-server/watson/?C=N;O=D)
- [5.0.x](http://couchbase:YAN3FrT7k@nas.service.couchbase.com/builds/latestbuilds/couchbase-server/spock/?C=N;O=D)
- [5.5.x](http://couchbase:YAN3FrT7k@nas.service.couchbase.com/builds/latestbuilds/couchbase-server/vulcan/?C=N;O=D)
- [6.x](http://couchbase:YAN3FrT7k@nas.service.couchbase.com/builds/latestbuilds/couchbase-server/alice/?C=N;O=D)
- [6.5.x](http://couchbase:YAN3FrT7k@nas.service.couchbase.com/builds/latestbuilds/couchbase-server/mad-hatter/?C=N;O=D)
- [6.6.x](http://couchbase:YAN3FrT7k@nas.service.couchbase.com/builds/latestbuilds/couchbase-server/mad-hatter/?C=N;O=D)
- [Cheshire-Cat](http://couchbase:YAN3FrT7k@nas.service.couchbase.com/builds/latestbuilds/couchbase-server/cheshire-cat/?C=N;O=D)
- Automatically "stops" every night, this is recurring and can be canceled for each night.  Automatically **terminates** after one month (can also be canceled)
- Manually stop and start environment, saves all progress. When completely done, please press "Terminate"

**Email daniel.bull@couchbase.com or sam.redman@couchbase.com with any feedback or problems.**
'

#########
# Resources
#########

resource 'eip', type: 'ip_address' do
    like @import.eip
end

resource 'volume', type: 'volume' do
    like @import.volume
end

resource 'cb_node', type: 'server' do
    like @import.server
    name 'Couchbase Server 5.x'
    multi_cloud_image_href map($os_mapping, $os, "mci_href")
    inputs do {
        'CB_SERVER_INSTALL' => 'text:TRUE',
        'CB_APP_NODE' => 'text:FALSE',
        'CB_SG_INSTALL' => 'text:FALSE',
        'CB_SERVER_CLUSTER' => 'text:TRUE',
        'CB_TRAVEL_DEMO' => 'text:TRUE'
    } end
end

resource 'app_node', type: 'server' do
    like @import.server
    name "Application Node"
    instance_type $app_nodes_instance
    multi_cloud_image_href map($os_mapping, $os, "mci_href")
    inputs do {
    #        'CB_TRAVEL_DEMO_PORT'=>'text:0',
    #        'CB_QUERY_LOAD'=>'text:0',
    #        'CB_KV_LOAD'=>'text:0',
    'CB_SERVER_INSTALL' => 'text:FALSE',
    'CB_APP_NODE' => 'text:FALSE' #don't want it to do anything
    } end
end

#########
# Parameters
#########

#Cluster Configuration

parameter "version" do
    like $import.version
    category "Cluster Configuration"
end

parameter "cb_url" do
    like $import.cburl
    category "Cluster Configuration"
end
parameter "os" do
    like $import.os
    category "Cluster Configuration"
    default "CentOS/RHEL 7.x"
end
parameter "region" do
    like $import.region
    category "Cluster Configuration"
end
parameter "indexstorage" do
    like $import.indexstorage
    category "Cluster Configuration"
end


#Node Groups
parameter "nodes_1" do
    type "number"
    label "Number of Nodes"
    max_value 25
    default 1
    category "Nodes 1"
    operations 'launch'
    description "\"Nodes 1-6\" will be combined into one cluster.  Choose the number of nodes, instance type, disk size and Couchbase services for each group to control MDS"
end
parameter "disk_1" do
    like $import.disk_size
    category "Nodes 1"
    operations 'launch'
end
parameter "instance_1" do
    like $import.instance_list
    category "Nodes 1"
    operations 'launch'
end
parameter "clustered_1" do
    type "list"
    label "Check this box to include these nodes in the cluster, leave unchecked for \"blank\" nodes"
    allowed_values "true", "false"
    default "true"
    category "Nodes 1"
    operations 'launch'
end
parameter "data_1" do
    like $clustered_1
    label "Data Service (at least one node in the cluster must have the data service)"
end
parameter "query_1" do
    like $data_1
    label "Query Service"
end
parameter "index_1" do
    like $data_1
    label "Index Service"
end
parameter "fts_1" do
    like $data_1
    label "FTS Service"
end
parameter "analytics_1" do
    like $data_1
    label "Analytics Service (>5.5).  When selected and disk size set to -1, any local SSD's will be treated as separate IO devices."
    default "false"
end
parameter "eventing_1" do
    like $data_1
    label "Eventing Service (>5.5)"
    default "false"
end
parameter "backup_1" do
    like $data_1
    label "Backup Service (>=7.0)"
    default "false"
end


[*2..6].each do |n|
    parameter "nodes_#{n}" do
        like $nodes_1
        default 0
        category "Nodes #{n}"
    end
    parameter "disk_#{n}" do
        like $disk_1
        category "Nodes #{n}"
    end
    parameter "instance_#{n}" do
        like $instance_1
        category "Nodes #{n}"
    end
    parameter "clustered_#{n}" do
        like $clustered_1
        category "Nodes #{n}"
    end
    parameter "data_#{n}" do
        like $data_1
        category "Nodes #{n}"
    end
    parameter "query_#{n}" do
        like $query_1
        default "false"
        category "Nodes #{n}"
    end
    parameter "index_#{n}" do
        like $index_1
        default "false"
        category "Nodes #{n}"
    end
    parameter "fts_#{n}" do
        like $fts_1
        default "false"
        category "Nodes #{n}"
    end
    parameter "analytics_#{n}" do
        like $analytics_1
        default "false"
        category "Nodes #{n}"
    end
    parameter "eventing_#{n}" do
        like $eventing_1
        default "false"
        category "Nodes #{n}"
    end
    parameter "backup_#{n}" do
        like $backup_1
        default "false"
        category "Nodes #{n}"
    end
end

parameter "app_nodes" do
    type "number"
    label "Number of Application Nodes"
    max_value 25
    default 0
    category "App Nodes"
    operations 'launch'
end
parameter "app_nodes_disk" do
    type "number"
    label "Disk Size in GB"
    max_value 4096
    default 0
    description "Size of the EBS Volume to be mounted on the node."
    category "App Nodes"
    operations 'launch'
end
parameter "app_nodes_instance" do
    like $import.instance_list
    category "App Nodes"
end

#Misc Configuration

parameter "security_group" do
    like $import.security_group
end

parameter "timeout" do
    like $import.timeout
end

parameter "cluster_port" do
    like $import.cluster_port
    category "Misc Configuration"
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

output "cluster" do
    label "Cluster:"
    category "Environment"
end

[*0..25].each do |n|
    output "nodes#{n}" do
        label "Node:"
        category "Couchbase Nodes"
    end
end

[*0..25].each do |n|
    output "app_nodes#{n}" do
        label "Node:"
        category "Application Nodes"
    end
end

output "guilogin" do
    like $import.guilogin
    category "Environment"
end

output "sshlogin" do
    like $import.sshlogin
    category "Environment"
end
#output "auto_stop" do
#    like $import.auto_stop
#    category "Environment"
#end
#output "shutoff" do
#    like $import.shutoff
#    category "Environment"
#end

#########
# Operations/Definitions
#########

parameter 'shutdown' do
    like $import.shutdown
    default 43829
    operations 'dummy'
end

operation 'dummy' do
    definition 'generated_dummy'
end

define generated_dummy() do
end

operation 'enable' do
    like $import.enable
end

operation 'start' do
    like $import.start
end

operation 'stop' do
    like $import.stop
end

operation 'terminate' do
    like $import.terminate
end

operation 'launch' do
    description 'Launch the application'
    definition 'generated_launch'

    hash = {
        $cluster => join(["http://",$cluster_ip,":", $cluster_port]),
    }

    [*0..25].each do |n|
        hash[eval("$app_nodes#{n}")] = switch(get(n,$app_nodes_dns),join([get(n,$app_nodes_dns)]),null)
    end

    [*0..25].each do |n|
        hash[eval("$nodes#{n}")] = switch( get(n,$all_nodes_dns), join([ "http://",get(n,$all_nodes_dns),":", $cluster_port ]), null)
    end

    output_mappings do
        hash
    end
end

define generated_launch(@app_node, $app_nodes_instance, $app_nodes_disk, $app_nodes, @cb_node, $region, $region_mapping, @eip, @volume, $version, $cb_url, $indexstorage, $os, $os_mapping, $cluster_port, $timeout, $app_nodes, $nodes_1, $disk_1, $instance_1, $clustered_1, $data_1, $query_1, $index_1, $fts_1, $analytics_1, $eventing_1, $backup_1, $nodes_2, $disk_2, $instance_2, $clustered_2, $data_2, $query_2, $index_2, $fts_2, $analytics_2, $eventing_2, $backup_2, $nodes_3, $disk_3, $instance_3, $clustered_3, $data_3, $query_3, $index_3, $fts_3, $analytics_3, $backup_3, $eventing_3, $nodes_4, $disk_4, $instance_4, $clustered_4, $data_4, $query_4, $index_4, $fts_4, $analytics_4, $eventing_4, $backup_4, $nodes_5, $disk_5, $instance_5, $clustered_5, $data_5, $query_5, $index_5, $fts_5, $analytics_5, $eventing_5, $backup_5, $nodes_6, $disk_6, $instance_6, $clustered_6, $data_6, $query_6, $index_6, $fts_6, $analytics_6, $eventing_6, $backup_6) return $cluster_ip, $app_nodes_dns, $all_nodes_dns on_error: import.handle_error("Launch Error"), timeout: $timeout, on_timeout: import.handle_timeout("Launch Timeout") do

    call import.validate_port($cluster_port)
    call import.get_url($os_mapping, $os, $version, $cb_url) retrieve $cb_url

    $cluster_ip = ''

    $app_nodes_dns = []
    $app_nodes_ips = []
    $all_nodes_dns = []
    $all_nodes_ips = []

    @cloud = rs_cm.clouds.empty()
    $eip_hash=''
    $cb_node_hash=''
    $app_node_hash=''
    $volume_hash=''
    $error = ''

    $inp = {
        'CB_SHUTDOWN':'text:',
        #        'CB_BUCKET':'text:travel-sample',
        #        'CB_CONFIG1_BUCKET_NAMES':'text:travel-sample',
        #        'CB_CONFIG2_BUCKET_TYPES':'text:couchbase',
        #        'CB_CONFIG3_BUCKET_AUTH':'text:sasl',
        #        'CB_CONFIG4_BUCKET_PASSWORD_OR_PORT':'text:""',
        #        'CB_CONFIG5_BUCKET_RAM':'text:-1',
        #        'CB_CONFIG6_BUCKET_REPLICA':'text:1',
        #        'CB_CONFIG7_BUCKET_EJECTION':'text:valueOnly',
        #        'CB_CONFIG8_BUCKET_PRIORITY':'text:high',
        #        'CB_CONFIG_CLUSTERNAME': join(['text:',split(@@deployment.name,"-")[0]]),
        'CB_CLUSTERNAME': join(['text:',split(@@deployment.name,"-")[0]]),
        'CB_CLUSTER_TAG' : join(['text:',last(split(@@deployment.name,"-"))]),
        #        'CB_SERVER_INSTALL':'text:TRUE',
        #'CB_RAMSIZE':'text:10000',
        #        'CB_URL':join(['text:',$cb_url]),
        'CB_SERVER_URL':join(['text:',$cb_url]),
        'CB_UI_PORT':join(['text:',$cluster_port]),
        'CB_INDEX_MODE':join(['text:',$indexstorage]),
        'CB_REBALANCE_COUNT':join(['text:',$rebalance_count])
    }

    concurrent return $cluster_ip, $all_nodes_ips, $all_nodes_dns, $app_nodes_dns on_error: import.handle_error("Main Launch Error:"),  wait_task: ["wait"] do
        sub task_name: "wait", task_label: "Waiting for Environment:" do
            wait_task env
        end

        sub task_label: "Launching Environment:", task_name: "env" do
            sub task_label: "Loading Objects:" do
                call import.log("Starting deployment, loading objects")
                concurrent return @cloud, $eip_hash, $cb_node_hash, $app_node_hash, $volume_hash on_error: import.handle_error("Object Loading Error:") do
                    sub task_label: "Updating Inputs" do
                        @@deployment.multi_update_inputs(inputs: $inp)
                    end
                    sub task_label: "Getting Cloud Info" do
                        @cloud = rs_cm.clouds.get(filter: ["name=="+map($region_mapping, $region, "cloud")])
                    end
                    sub task_label: "Initializing EIP" do
                        $eip_hash=to_object(@eip)
                    end
                    sub task_label: "Initializing Couchbase Node" do
                        $cb_node_hash=to_object(@cb_node)
                    end
                    sub  task_label: "Initializing App Node" do
                        $app_node_hash=to_object(@app_node)
                    end
                    sub task_label: "Initializing Volume" do
                        $volume_hash=to_object(@volume)
                    end
                end
            end
            concurrent return $cluster_ip, $all_nodes_ips, $all_nodes_dns, $app_nodes_dns on_error: import.handle_error("Node Launch Error:") do
                sub task_name: "apps", on_error: import.handle_error("App Server Launch Error:") do
                    if $app_nodes > 0
                        call import.log("Launching " + to_s($app_nodes) + " application nodes")
                        $node_hash = $app_node_hash
                        call import.log("App Node hash: " + to_s($node_hash))
                        call import.launch_nodes("Application", $app_nodes, $app_nodes_instance, $app_nodes_disk, $node_hash, @eip, $volume_hash, @cloud) retrieve $app_nodes_ips, $app_nodes_dns task_label: "Launching App nodes:"
                        call import.log("Launched " + to_s($app_nodes) + " application nodes: " + to_s($app_nodes_ips) + ", " + to_s($app_nodes_dns))
                    end
                end

                sub task_name: "cluster", on_error: import.handle_error("Cluster Launch Error:") do
                    $groups = [
                        {"name": "Group 1", "nodes": $nodes_1, "disk": $disk_1, "instance": $instance_1, "clustered": $clustered_1, "data": $data_1, "query": $query_1, "index": $index_1, "fts": $fts_1, "analytics": $analytics_1, "eventing": $eventing_1, "backup": $backup_1, "services":''},
                        {"name": "Group 2", "nodes": $nodes_2, "disk": $disk_2, "instance": $instance_2, "clustered": $clustered_2, "data": $data_2, "query": $query_2, "index": $index_2, "fts": $fts_2, "analytics": $analytics_2, "eventing": $eventing_2, "backup": $backup_2, "services":''},
                        {"name": "Group 3", "nodes": $nodes_3, "disk": $disk_3, "instance": $instance_3, "clustered": $clustered_3, "data": $data_3, "query": $query_3, "index": $index_3, "fts": $fts_3, "analytics": $analytics_3, "eventing": $eventing_3, "backup": $backup_3, "services":''},
                        {"name": "Group 4", "nodes": $nodes_4, "disk": $disk_4, "instance": $instance_4, "clustered": $clustered_4, "data": $data_4, "query": $query_4, "index": $index_4, "fts": $fts_4, "analytics": $analytics_4, "eventing": $eventing_4, "backup": $backup_4, "services":''},
                        {"name": "Group 5", "nodes": $nodes_5, "disk": $disk_5, "instance": $instance_5, "clustered": $clustered_5, "data": $data_5, "query": $query_5, "index": $index_5, "fts": $fts_5, "analytics": $analytics_5, "eventing": $eventing_5, "backup": $backup_5, "services":''},
                        {"name": "Group 6", "nodes": $nodes_6, "disk": $disk_6, "instance": $instance_6, "clustered": $clustered_6, "data": $data_6, "query": $query_6, "index": $index_6, "fts": $fts_6, "analytics": $analytics_6, "eventing": $eventing_6, "backup": $backup_6, "services":''}
                    ]
                    call import.log("Launching Cluster: " + to_s($groups))
                    $node_hash = $cb_node_hash
                    call import.log("Node hash: " + to_s($node_hash))
                    call import.launch_cluster($groups, $node_hash, $cb_url, $indexstorage, @eip) retrieve $cluster_ip, $all_nodes_ips, $all_nodes_dns task_label: "Launching Cluster:"
                    call import.log("Launched cluster:" + to_s($cluster_ip) + "," + to_s($all_nodes_ips) + "," + to_s($all_nodes_dns))
                end
            end
        end
    end
end

define get_instance_by_tag($tag) return @instance do
    $tags_response = rs_cm.tags.by_tag(resource_type:"instances",tags:[ $tag ])
    $instance_href = first(first(first($tags_response))["links"])["href"]
    @instance = rs_cm.instances.get(href: $instance_href)
end
