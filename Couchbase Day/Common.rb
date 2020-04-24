name 'Common Params'
rs_ca_ver 20160622
package "package/common"
short_description 'CAT file of helper function, parameters, outputs and resources'

#########
# Resources
#########

resource 'eip', type: 'ip_address' do
    name "Couchbase"
    cloud map($region_mapping, $region, "cloud")
    domain "vpc"
end

resource 'node', type: 'server' do
    cloud map($region_mapping, $region, "cloud")
    subnets "VPC"
    instance_type 'c4.2xlarge'
    ssh_key 'Perry_Couchbase'
    multi_cloud_image find(map($os_mapping, $os, "mci"))
    cloud_specific_attributes do {
        "automatic_instance_store_mapping" => "true",
        "associate_public_ip_address" => "false",
    } end
end

resource 'node_spot', type: 'server' do
    like @node
    cloud_specific_attributes do {
        "automatic_instance_store_mapping" => "true",
        "associate_public_ip_address" => "false",
        "pricing_type" => "spot",
        "max_spot_price" => '2.00',
    } end
end

resource 'cb_node', type: 'server' do
    like @node
    name 'Couchbase Server 4.5'
    server_template find('Couchbase Server 4.0 - Self-Service')#, revision: 23)
end

resource 'cb_node_spot', type: 'server' do
    like @node_spot
    name 'Couchbase Server 4.5'
    server_template find('Couchbase Server 4.0 - Self-Service')#, revision: 23)
end

resource 'app_node', type: 'server' do
    like @node
    name 'zApp_node'
    server_template find('CBSClient 4.0 Travel App', revision: 23)
end

resource 'app_node_spot', type: 'server' do
    like @node_spot
    name 'zApp_node'
    server_template find('CBSClient 4.0 Travel App', revision: 23)
end

#########
# Parameters
#########

parameter "region" do
    type "list"
    label "Region"
    allowed_values "EC2 Oregon (us-west-2)", "EC2 Virginia (us-east-1)", "EC2 Nor Cal (us-west-1)","EC2 Ireland (eu-west-1)", "EC2 Singapore (ap-southeast-1)", "EC2 Sao Paulo (sa-east-1)"
    default "EC2 Oregon (us-west-2)"
    operations 'launch'
end
parameter "shutdown" do
    type "number"
    label "Shutdown in minutes"
    default 240
end
parameter "cluster_port" do
    type "number"
    label "Override UI/REST port when blocked by network.  Must be >1023, <65536 and not: 4369, 8092 to 8094, 9100 to 9105, 9998, 9999, 11209 to 11211, 11214, 11215, 18091 to 18094, and 21100 to 21299"
    min_value 1024
    max_value 65535
    default 8091
end
parameter "disk_size" do
    type "number"
    label "Disk size in GB:"
    min_value 10
    max_value 1024
    default 10
end

parameter "instance_list" do  #template for list of indexes
    type "list"
    label "Instance type:"
    allowed_values "m5.2xlarge", "m5.4xlarge", "c4.2xlarge", "c4.4xlarge", "c4.8xlarge", "r3.2xlarge", "r3.4xlarge","i2.2xlarge","i2.4xlarge"
    default "c4.2xlarge"
end

parameter "os" do
    type "list"
    label "Operating System"
    allowed_values "CentOS/RHEL 6.x", "CentOS/RHEL 7.x", "Ubuntu 12"#, "Amazon Linux"#, "Ubuntu 14"
    default "CentOS/RHEL 6.x"
    operations 'launch'
end

parameter "version" do
    type "list"
    label "Couchbase Version"
    allowed_values "4.1.0", "4.1.1", "4.5.0", "Any URL"#/, "Latest 4.5.1 (or supply build number)", "Latest Spock (or supply build number)", "Any URL"
    default "4.5.0"
end
#########
# Mappings
#########

mapping "os_mapping" do {
    "Amazon Linux" => {
        "mci" => "Couchbase - Amazon Linux",
        "mci_href" => "/api/multi_cloud_images/411651003",
        "os" => "-centos6.x86_64.rpm",
        "del" => "-"
    },
    "CentOS/RHEL 6.x" => {
        "mci" => "RightImage_CentOS_6.6_x64_v14.2_HVM_EBS",
        "mci_href" => "/api/multi_cloud_images/414072003",
        "os" => "-centos6.x86_64.rpm",
        "del" => "-"
    },
    "CentOS/RHEL 7.x" => {
        "mci" => "RightImage_CentOS_7.0_x64_v14.2_HVM_EBS",
        "mci_href" => "/api/multi_cloud_images/409407003",
        "os" => "-centos7.x86_64.rpm",
        "del" => "-"
    },
    "Ubuntu 12" => {
        "mci" => "RightImage_Ubuntu_12.04_x64_v14.2_HVM_EBS",
        "mci_href" => "/api/multi_cloud_images/414073003",
        "os" => "-ubuntu12.04_amd64.deb",
        "del" => "_"
    },
    "Ubuntu 14" => {
        "mci" => "RightImage_Ubuntu_14.04_x64_v14.2_HVM_EBS",
        "mci_href" => "/api/multi_cloud_images/414074003",
        "os" => "-ubuntu14.04_amd64.deb",
        "del" => "_"
    },
    "4.1.0" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "4.1.0"
    },
    "4.1.1" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "4.1.1"
    },
    "4.5.0" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "4.5.0"
    },
    "Any URL" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "url"
    },
} end

mapping "region_mapping" do {
    "EC2 Oregon (us-west-2)" => {
        "datacenter" => "us-west-2a",
        "cloudnum" => "6",
        "cloud" => "EC2 us-west-2"
    },
    "EC2 Nor Cal (us-west-1)" => {
        "datacenter" => "us-west-1a",
        "cloudnum" => "3",
        "cloud" => "EC2 us-west-1"
    },
    "EC2 Virginia (us-east-1)" => {
        "datacenter" => "us-east-1a",
        "cloudnum" => "1",
        "cloud" => "EC2 us-east"
    },
    "EC2 Singapore (ap-southeast-1)" => {
        "datacenter" => "ap-southeast-1a",
        "cloudnum" => "4",
        "cloud" => "AWS ap-southeast-1"
    },
    "EC2 Ireland (eu-west-1)" => {
        "datacenter" => "eu-west-1a",
        "cloudnum" => "2",
        "cloud" => "EC2 eu-west-1"
    },
    "EC2 Sao Paulo (sa-east-1)" => {
        "datacenter" => "sa-east-1a",
        "cloudnum" => "7",
        "cloud" => "EC2 sa-east-1"
    }
} end

#########
# Outputs
#########

output "guilogin" do
    label "Cluster GUI Login"
    category "Demo"
    default_value "Administrator/password"
end
output "sshlogin" do
    label "SSH Login Information User/Pass:"
    category "Demo"
    default_value "root/couchbase123!"
end
output "shutoff" do
    label "Reminder:"
    category "Demo"
    default_value "This demo will shut down automatically 4 hours after starting."
end

#########
# Operations/Definitions
#########

define enable($shutdown) do
    #call common.schedule_terminate($shutdown, "stop", "no")
    #call recurring_shutdown($shutdown)
end

define terminate() do
    if !$$all_terminated
        $$all_terminated = true
        @servers = @@deployment.servers()
        concurrent do
            delete(@servers)
            if $$error != null
                raise "Encountered an error and shutdown.  Please attempt to launch a new deployment.\n" + $$error["message"]
            end
        end
    end
end
#define start($shutdown) do
define start() do
    if !$$all_started
        $$all_started = true

        @@deployment.servers().current_instance().start()
        $operational = false

        sub task_label: "Starting Environment:", timeout: 10m, on_error: common.cancel() do
            $wake_condition = /^(operational|booting|stranded|stranded in booting|stopped|provisioned|terminated|inactive|error)$/

            @servers = @@deployment.servers()
            sleep_until(all?(@servers.state[], $wake_condition))

            $operational = all?(@servers.state[], /^(operational|booting)$/)
            call log(to_s(@servers.state))
        end

        if !$operational
            raise "Failed to start some servers!"
        end

        #call schedule_terminate($shutdown, "stop", "no")
        call recurring_shutdown(1)
    end
end


define stop() do
    if !$$all_stopped
        $$all_stopped = true

        @@deployment.servers().current_instance().stop()
        $stopped = false

        sub task_label: "Stopping Environment:", timeout: 10m, on_error: common.cancel() do
            $wake_condition = /^(operational|stranded|stranded in booting|stopped|provisioned|terminated|inactive|error)$/

            @servers = @@deployment.servers()
            sleep_until(all?(@servers.state[], $wake_condition))

            $stopped = all?(@servers.state[], /^(stopped|provisioned)$/)
            call log(to_s(@servers.state))
        end

        if !$stopped
            raise "Failed to stop some servers!"
        end
    end
end

define bulk_launch(@resource, $number, $name, @eip) return $ips, $dns do

    $partial = 0;
    if index($name, "Blank") || index($name, "App")
        $partial = 1
        call log("Starting a partial launch of " + to_s($number) + " " + $name + " nodes")
        else
        call log("Starting to launch " + to_s($number) + " " + $name + " nodes")
    end

    @allnodes = concurrent map $item in [1..$number] return @instance on_error: cancel() do
        concurrent return @resource,@eip on_error: cancel() do
            call create_server(@resource) retrieve @resource
            provision(@eip)
        end
        call log("#" + to_s($item) + " " + $name + " server created and EIP provisioned")

        @eip.ip_address_bindings().create(instance_href: @resource.next_instance().href, public_ip_address_href: @eip.href)
        call log("#" + to_s($item) + " " + $name + " EIP bound")

        call launch_server(@resource, $name, $partial) retrieve @resource
        call log("#" + to_s($item) + " " + $name + " server launched, partial="+$partial)

        @instance = @resource.current_instance()
        $ip = @eip.address
        sleep_until( @instance.public_ip_addresses[0] == $ip )
        sleep_until( size(@instance.public_dns_names[0]) > 0 )
        call log("#" + to_s($item) + " " + $name + " IP and DNS discovered")
    end

    call log("Finished concurrent map launching " + to_s($number) + " " + $name + " node")
    @allnodes = @allnodes.get()

    $dns = []
    $ips = []
    foreach @node in @allnodes do
        $dns << @node.public_dns_names[0]
        $ips << @node.public_ip_addresses[0]
    end
    call log("IPs ready for " + to_s($number) + " " + $name + " nodes")
end

define launch_nodes($name, $number, $disk, @resource, @eip) return $ips, $dns do
    sub task_label:"Launching "+$number+" "+$name+" Nodes", on_error: common.cancel() do
        if $number > 0
            #setting data node's root volume
            $server_hash = to_object(@resource)
            $server_hash['fields']['cloud_specific_attributes']['root_volume_size'] = to_n($disksize) + 10
            @resource = $server_hash
            #bulk launching instances
            call bulk_launch(@resource, $number, $name, @eip) retrieve $ips, $dns
            else
            $ips = []
            $dns = []
        end
    end
end

define launch_server(@server, $name, $partial) return @server do
    @server.launch()

    if $partial == 1
        $wake_condition = /^(booting|operational|stranded|stranded in booting|stopped|provisioned|terminated|inactive|error)$/
        else
        $wake_condition = /^(operational|stranded|stranded in booting|stopped|provisioned|terminated|inactive|error)$/
    end

    sleep_until (@server.state =~ $wake_condition)

    if (@server.state !~ /^(operational|booting)$/ )
        raise "Failed to start @server !"
    end
end

define create_server(@server) return @server do
    $s = to_object(@server)
    $fields = $s['fields']
    @server = rs_cm.servers.create($fields)
end

define cancel() do
    $$error = $_error
    if $$error != null
        raise "Encountered an error and shutdown.  Please attempt to launch a new deployment.\n" + $$error["message"]
    end
    cancel # Cancels all tasks in the entire process
end

define api_error($response, $line_number) do
    raise to_s($line_number) + ": Error hitting SS API\n" + to_s($response["code"]) + ": " + to_s($response["headers"]["status"]) + "-" + to_s($response["body"])
end

define log($message) do
    if size($message) > 250
        rs_cm.audit_entries.create(notify: "None", audit_entry: {auditee_href: @@deployment.href, summary: "CloudAppLog", detail: to_s($message)})
        else
        rs_cm.audit_entries.create(notify: "None", audit_entry: {auditee_href: @@deployment.href, summary: to_s($message), detail: to_s($message)})
    end
end

define validate_port($cluster_port) do
    if $cluster_port == 4369 || ($cluster_port >= 8092 && $cluster_port <= 8094) || ($cluster_port >= 9100 && $cluster_port <= 9105) || $cluster_port == 9998 || $cluster_port == 9999 || ($cluster_port >= 11209 && $cluster_port <= 11211) || $cluster_port == 11214 || $cluster_port == 11215 || ($cluster_port >= 18091 && $cluster_port <= 18093) || ($cluster_port >= 21100 && $cluster_port <= 21299)
        raise "UI Port is invalid.  Must be >1023, <65536 and not: 4369, 8092 to 8094, 9100 to 9105, 9998, 9999, 11209 to 11211, 11214, 11215, 18091 to 18093, and 21100 to 21299"
        call cancel()
    end
end

define recurring_shutdown($minutes) do
    call get_current_user_timezone() retrieve $tz
    #    $time = now() + ($minutes * 60)
    #    rs_ss.scheduled_actions.create(execution_id: @@execution.id, action: "stop", first_occurrence: $time, timezone: $tz, recurrence: "FREQ=DAILY;")
    rs_ss.scheduled_actions.create(execution_id: @@execution.id, action: "stop", first_occurrence: "2016-01-01T00:00:00+00:00", timezone: $tz, recurrence: "FREQ=DAILY;")
end

define schedule_terminate( $minutes, $action, $override) do
    $time = now() + ($minutes * 60)

    @event = rs_ss.scheduled_actions.get(filter: [ "execution.created_by==me", "execution_id==" + @@execution.id])
    if size(@event) > 0
        if $override == "yes"
            @event.delete()
            @event = rs_ss.scheduled_actions.create(execution_id: @@execution.id, action: $action, first_occurrence: $time)
        end
        else
        @event = rs_ss.scheduled_actions.create(execution_id: @@execution.id, action: $action, first_occurrence: $time)
    end

end

define reset_terminate($shutdown) do
    call recurring_shutdown($shutdown)
    #call common.schedule_terminate($shutdown, "stop", "yes")
end

define get_url($os_mapping, $os, $version, $cburl) return $url do
    #full url =                        <base_url>                                                      / <version url>   / <couchbase-server-enterprise>   <del>    <version/build url>            <os>
    #eg: <https://s3.amazonaws.com/packages.couchbase.com/releases>                                    /  4.5.0-beta     /  couchbase-server-enterprise    [- _]    4.5.0-beta      -centos6.x86_64.rpm
    #eg: <http://couchbase:north$cale@nas.service.couchbase.com/builds/latestbuilds/couchbase-server>  /  watson/2600    /  couchbase-server-enterprise    [- _]    4.5.0-2600      -centos6.x86_64.rpm

    $version_url = map($os_mapping, $version, "version")

    $url = join([map($os_mapping,$version,"baseurl"), $version_url, "/couchbase-server-enterprise",map($os_mapping,$os,"del"),$version_url,map($os_mapping,$os,"os")])

    if $version_url == "url"
        $url = $cburl
    end
end

define get_current_user_timezone() return $tz do
    # Get the preferences for the current user and find the timezone preference
    @prefs = rs_ss.user_preferences.get(filter:["user_id==me"], view:"expanded")
    @prefs = select(@prefs, {"user_preference_info":{"name":"time_zone"}})

    # Get the value of the timezone if one exists
    if size(@prefs) > 0
        $tz = @prefs.value
    end

    # If there is no value, get the default from the API
    if !$tz
        @info = rs_ss.user_preference_infos.get(filter:["name==time_zone"])
        $tz = @info.default_value
    end
end
