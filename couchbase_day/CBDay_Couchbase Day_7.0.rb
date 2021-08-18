name 'Couchbase Day 7.0'
rs_ca_ver 20160622
import "package/common"

short_description 'Couchbase Day Sandbox: 1 7.0.0 Couchbase Server & 1 Application Server'

###########
# Resources
###########
resource 'eip', type: 'ip_address' do
    like @common.eip
end

resource 'all_services_node', type: 'server' do
    like @common.cb_node
    name 'Couchbase Server 7.0 - Data/Query/Index/FTS'
    inputs do {
        'CB_SERVICES' => 'text:data,index,query,fts,analytics,eventing'# --index-storage-setting=default'
    } end
end

resource 'app_node', type: 'server' do
    like @common.app_node
    inputs do {
        'CB_QUERY_LOAD'=>'text:0',
        'CB_KV_LOAD'=>'text:0',
    } end
end

#########
# Parameters
#########

parameter "region" do
    like $common.region
end
parameter "cluster_port" do
    like $common.cluster_port
end
parameter "os" do
    like $common.os
    allowed_values "CentOS/RHEL 7.x"
    default "CentOS/RHEL 7.x"
end
parameter "shutdown" do
    type "number"
    label "Shutdown Timer"
    description "Overridden to 600, value must be 600"
    allowed_values 600
    default 600
end
#########
# Mappings
#########

mapping "region_mapping" do
    like $common.region_mapping
end
mapping "os_mapping" do
    like $common.os_mapping
end
#########
# Outputs
#########

output "couchbase_fqdn" do
    label "Couchbase 7.0.0 Node 1 FQDN:"
    category "Demo"
end

output "couchbase" do
    label "Couchbase 7.0.0 Node 1:"
    category "Demo"
end

output "client_fqdn" do
    label "Couchbase 7.0.0 Node 2 FQDN:"
    category "Demo"
end

output "client" do
    label "Couchbase 7.0.0 Node 2:"
    category "Demo"
end

output "guilogin" do
    like $common.guilogin
end
output "sshlogin" do
    like $common.sshlogin
end
output "shutoff" do
    like $common.shutoff
end

##########
# Operations
##########

operation 'terminate' do
    definition 'common.terminate'
end

operation 'enable' do
    definition 'enable'
end

define enable($shutdown) do
    call common.schedule_terminate($shutdown, "terminate", "no")
end

operation 'launch' do
    description 'Launch the application'
    definition 'generated_launch'
    output_mappings do {
        $couchbase => join(["http://", $cluster_ip, ":", $cluster_port]),
        $couchbase_fqdn => join(["http://", $cluster_dns, ":", $cluster_port]),
        $client => join(["http://",$app_node_ip, ":",$cluster_port]),
        $client_fqdn => join(["http://", $app_node_dns, ":", $cluster_port])
    } end
end
define generated_launch(@eip,@all_services_node,@app_node, $cluster_port,$shutdown)  return $cluster_ip, $cluster_dns, $app_node_ip, $app_node_dns  do
    $inp = {
        'CB_SHUTDOWN':join(['text:',$shutdown+5]),
        'CB_ROOT_SSH_AUTH':'text:1',
        'CB_BUCKET':'text:travel-sample',
        'CB_CONFIG1_BUCKET_NAMES':'text:travel-sample,beer-sample',
        'CB_CONFIG2_BUCKET_TYPES':'text:couchbase,couchbase',
        'CB_CONFIG3_BUCKET_AUTH':'text:sasl,sasl',
        'CB_CONFIG4_BUCKET_PASSWORD_OR_PORT':'text:"",""',
        'CB_CONFIG5_BUCKET_RAM':'text:-1,-1',
        'CB_CONFIG6_BUCKET_REPLICA':'text:1,1',
        'CB_CONFIG7_BUCKET_EJECTION':'text:valueOnly,valueOnly',
        'CB_CONFIG8_BUCKET_PRIORITY':'text:high,high',
        'CB_CONFIG_CLUSTERNAME': join(['text:',split(@@deployment.name,"-")[0]]),
        'CB_CLUSTER_TAG' : join(['text:',last(split(@@deployment.name,"-"))]),
        'CB_INSTALL':'text:TRUE',
        'CB_RAMSIZE':'text:10000',
        'CB_REBALANCE_COUNT':'text:1',
        'CB_URL':'text:https://packages.couchbase.com/releases/7.0.0/couchbase-server-enterprise-7.0.0-centos7.x86_64.rpm',
        'LCB_VER':'text:2.5.1',
        'CB_UI_PORT':join(['text:',$cluster_port])
    }

    @@deployment.multi_update_inputs(inputs: $inp)

    call common.validate_port($cluster_port)
    $timeout="30m"

    sub task_label:"Provisioning infrastructure", on_rollback: common.terminate() do
        concurrent return  $cluster_ip, $cluster_dns, $app_node_ip, $app_node_dns on_error: common.cancel() do
            call common.launch_nodes("Couchbase", 1, 0, @all_services_node, @eip)      retrieve $cluster_ip, $cluster_dns  timeout: $timeout, on_timeout: common.terminate()
            call common.launch_nodes("Application", 1, 0, @app_node, @eip)             retrieve $app_node_ip, $app_node_dns  timeout: $timeout, on_timeout: common.terminate()
        end
    end
end
