name 'Common Definitions v2'
rs_ca_ver 20161221
package "package/se_common"
short_description 'CAT file of helper functions'


#########
# Parameters
#########

parameter "region" do
    type "list"
    label "AWS Region"
    allowed_values "EC2 Oregon (us-west-2)", "EC2 Virginia (us-east-1)", "EC2 Nor Cal (us-west-1)","EC2 Ireland (eu-west-1)", "EC2 Singapore (ap-southeast-1)"
    default "EC2 Oregon (us-west-2)"
    operations 'launch'
end
parameter "shutdown" do
    type "number"
    label "Auto Shutdown in minutes"
    default 240
end
parameter "cluster_port" do
    type "number"
    label "Override UI/REST port when blocked by network.  Must be >1023, <65536 and not: 4369, 8092 to 8095, 9100 to 9105, 9998, 9999, 11209 to 11211, 11214, 11215, 18091 to 18094, and 21100 to 21299"
    min_value 1024
    max_value 65535
    default 8091
end
parameter "sg_port" do
    type "number"
    label "Override Sync Gateway port when blocked by network.  Must be >1023, <65536."
    min_value 1024
    max_value 65535
    default 4984
end
parameter "disk_size" do
    type "number"
    label "Disk size in GB"
    #    min_value 0
    max_value 4096
    default 0
    description "The root partition is always 10GB, and is used for the Couchbase installation directory.  Data & index directories will use /couchbase.  If disk size here is >0, an EBS drive of this size is mounted to /couchbase.  If 0, /couchbase will be created on the root partition.    Some instance types may provide local SSDs.  These are mounted to /ephemeral and will NOT persist across a stop/start cycle.  Set this value to -1 to map /couchbase to local SSDs if available (data will NOT be available after start/stop/restart)."
    #description "The root (/) partition has 10GB of EBS storage, if you need more, enter a value up to 1024 for EBS disk (\"General Purpose\").  This will automatically be mounted as /couchbase and the nodes configured to use it as their data AND index paths.  Some instances also come with \"ephemeral\" storage but this will NOT be persistent across a stop/start cycle"
end

parameter "instance_list" do  #template for list of instances
    type "list"
    label "Instance type"
    allowed_values \
        "--Compute Optimised--",
        #"c3.large", "c3.xlarge", "c3.2xlarge", "c3.4xlarge", "c3.8xlarge",
        "c4.large", "c4.xlarge", "c4.2xlarge", "c4.4xlarge", "c4.8xlarge",
        "c5.large", "c5.xlarge", "c5.2xlarge", "c5.4xlarge", "c5.9xlarge",
        "c5d.large", "c5d.xlarge", "c5d.2xlarge", "c5d.4xlarge", "c5d.9xlarge",
        "--Storage Optimised--",
        #"i2.2xlarge", "i2.4xlarge", "i2.8xlarge",
        "i3.2xlarge", "i3.4xlarge", "i3.8xlarge",
        "d2.xlarge", "d2.2xlarge", "d2.4xlarge", "d2.8xlarge",
        "--General Purpose--",
        "m4.xlarge", "m4.2xlarge", "m4.4xlarge", "m4.10xlarge",
        "m5.xlarge", "m5.2xlarge", "m5.4xlarge",
        "m5d.xlarge", "m5d.2xlarge", "m5d.4xlarge", "m5d.12xlarge",
        "--Memory Optimised--",
        #"r3.2xlarge", "r3.4xlarge", "r3.8xlarge",
        "r4.xlarge", "r4.2xlarge", "r4.4xlarge", "r4.8xlarge",
        "r5.xlarge", "r5.2xlarge", "r5.4xlarge",
        "r5d.xlarge", "r5d.2xlarge", "r5d.4xlarge", "r5d.12xlarge"
    default "m4.xlarge"
    description "Only CentOS/RHEL 7, Amazon Linux and Ubuntu 16 are compatible with gen-5 instance types."
end

parameter "os" do
    type "list"
    label "Operating System"
    allowed_values "CentOS/RHEL 6.x", "CentOS/RHEL 7.x", "Ubuntu 12", "Ubuntu 14", "Ubuntu 16", "Amazon Linux", "Amazon Linux 2", "RHEL OSE"
    description "Only CentOS/RHEL 7, Amazon Linux and Ubuntu 16 are compatible with gen-5 instance types. See https://docs.couchbase.com/server/6.0/install/install-platforms.html for supported platforms by version of Couchbase Server/SGW"
    default "CentOS/RHEL 7.x"
    operations 'launch'
end

parameter "version" do
  type "list"
  label "Couchbase Server Version"
  allowed_values "4.1.0", "4.1.1", "4.5.0", "4.5.1", "4.6.0", "4.6.1", "4.6.2", "4.6.3","4.6.4","4.6.5","5.0.1","5.1.1","5.5.1","5.5.2","5.5.3","6.0.0","6.0.1","6.0.2","6.0.3", "6.5.0", "6.5.1", "Mad-Hatter-latest", "Cheshire-Cat-latest", "Magma-Preview-latest"
  default "6.5.0"
  description "6.5.0 Now Available!"
end
parameter "cbserver_version" do
    like $version
end
parameter "sg_version" do
    type "list"
    label "Couchbase Sync Gateway Version"
    allowed_values "1.5.0", "2.6.0", "2.7.0"
    default "2.7.0"
    description ""
end
parameter "cbsg_version" do
    like $sg_version
end
parameter "cburl" do
    type "string"
    label "Couchbase Server URL (overrides above selection)"
    max_length 1024
    description "Make sure to use the right URL according to the Operating System chosen below.  For Amazon Linux, use a CentOS 6 RPM."
end
parameter "cbserver_url" do
    like $cburl
end
parameter "sgurl" do
    type "string"
    label "Couchbase Sync Gateway URL (overrides above selection)"
    max_length 1024
    description "Make sure to use the right URL according to the Operating System chosen below.  For Amazon Linux, use a CentOS 6 RPM."
end
parameter "cbsg_url" do
    like $sgurl
end

parameter "indexstorage" do
    type "list"
    label "Index Storage mode (non-MDS in 4.5/4.5.x, MDS in 4.6.0+)"
    allowed_values "default", "memopt"
    default "default"
    description "If you need MOI with MDS in pre-4.6.0 you will need to manually configure it after the cluster is initially setup.  Do so by removing all index nodes, changing the setting and re-adding them.  Remember that this is an EE-only feature."
end

parameter "security_group" do
    type "list"
    category "Misc Configuration"
    allowed_values "true", "false"
    default "false"
    label "Open all ports - Note that this is considered insecure and no customer or sensitive data should be placed in this environment.  Defaults to all ports blocked except 22/8091/8095/3000/8080"
end

parameter "timeout" do
    type "string"
    label "Launch timeout in \"d\"ays, \"h\"ours, \"m\"inutes, or \"s\"econds."
    default "60m"
    allowed_pattern "\\d+[dhms]"
    constraint_description "Must match: \"\\d+[dhms]\" i.e 60m"
end

#########
# Mappings
#########

mapping "os_mapping" do {
    "Amazon Linux" => {
        "mci" => "Couchbase - Amazon Linux",
        "mci_href" => "/api/multi_cloud_images/411651003",
        "mci_href2" => "/api/multi_cloud_images/432567003",
        "os" => "-centos6.x86_64.rpm",
        "del" => "-"
    },
    "Amazon Linux 2" => {
        "mci" => "Couchbase - Amazon Linux 2",
        "mci_href" => "/api/multi_cloud_images/444748003",
        "mci_href2" => "/api/multi_cloud_images/432567003",
        "os" => "-amzn2.x86_64.rpm",
        "del" => "-"
    },
    "CentOS/RHEL 6.x" => {
        "mci" => "RightImage_CentOS_6.6_x64_v14.2_HVM_EBS",
        "mci_href" => "/api/multi_cloud_images/432590003",
        "mci_href2" => "/api/multi_cloud_images/414072003",
        "os" => "-centos6.x86_64.rpm",
        "del" => "-"
    },
    "CentOS/RHEL 7.x" => {
        "mci" => "Couchbase_CentOS_7.0_x64_v1_HVM_EBS",
        "mci_href" => "/api/multi_cloud_images/420707003",
        "mci_href2" => "/api/multi_cloud_images/432607003",
        "os" => "-centos7.x86_64.rpm",
        "del" => "-"
    },
    "CentOS/RHEL 8.x" => {
        "mci" => "Couchbase_RHEL_8_x64_v1_HVM_EBS",
        "mci_href" => "/api/multi_cloud_images/444807003",
        "mci_href2" => "/api/multi_cloud_images/444807003",
        "os" => "-centos8.x86_64.rpm",
        "del" => "-"
    },
    "Ubuntu 12" => {
        "mci" => "RightImage_Ubuntu_12.04_x64_v14.2_HVM_EBS",
        "mci_href" => "/api/multi_cloud_images/432592003",
        "mci_href2" => "/api/multi_cloud_images/432606003",
        "os" => "-ubuntu12.04_amd64.deb",
        "del" => "_"
    },
    "Ubuntu 14" => {
        "mci" => "RightImage_Ubuntu_14.04_x64_v14.2_HVM_EBS",
        "mci_href" => "/api/multi_cloud_images/432593003",
        "mci_href2" => "/api/multi_cloud_images/432605003",
        "os" => "-ubuntu14.04_amd64.deb",
        "del" => "_"
    },
    "Ubuntu 16" => {
        "mci" => "Couchbase_Ubuntu_16.04_x64_v1_HVM_EBS",
        "mci_href" => "/api/multi_cloud_images/434580003",
        "mci_href2" => "/api/multi_cloud_images/441166003",
        "os" => "-ubuntu16.04_amd64.deb",
        "del" => "_"
    },
    "RHEL OSE" => {
        "mci" => "Couchbase - OSE",
        "mci_href" => "/api/multi_cloud_images/420618003",
        "mci_href2" => "/api/multi_cloud_images/432568003",
        "os" => "-centos7.x86_64.rpm",
        "del" => "-"
    },
    "1.5.0" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "sg_version" => "1.5.0"
    },
    "2.6.0" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "sg_version" => "2.6.0"
    },
    "2.7.0" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "sg_version" => "2.7.0"
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
    "4.5.1" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "4.5.1"
    },
    "4.6.0" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "4.6.0"
    },
    "4.6.1" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "4.6.1"
    },
    "4.6.2" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "4.6.2"
    },
    "4.6.3" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "4.6.3"
    },
    "4.6.4" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "4.6.4"
    },
    "4.6.5" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "4.6.5"
    },
    "5.0.0" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "5.0.1"
    },
    "5.0.1" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "5.0.1"
    },
    "5.1.0" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "5.1.0"
    },
    "5.1.1" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "5.1.1"
    },
    "5.5.1" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "5.5.1"
    },
    "5.5.2" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "5.5.2"
    },
    "5.5.3" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "5.5.3"
    },
    "6.0.0" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "6.0.0"
    },
    "6.0.1" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "6.0.1"
    },
    "6.0.2" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "6.0.2"
    },
    "6.0.3" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "6.0.3"
    },
    "6.5.0" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "6.5.0"
    },
    "6.5.1" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "6.5.1"
    },
    "Any URL" => {
        "baseurl" => "https://s3.amazonaws.com/packages.couchbase.com/releases/",
        "version" => "url"
    },
    "Mad-Hatter-latest" => {
      "baseurl" => "http://nas.service.couchbase.com/builds/latestbuilds/couchbase-server/mad-hatter/latest",
      "version" => "mad-hatter-preview"
    },
    "Cheshire-Cat-latest" => {
        "baseurl" => "http://nas.service.couchbase.com/builds/latestbuilds/couchbase-server/cheshire-cat/latest",
        "version" => "cheshire-cat"
    },
    "Magma-Preview-latest" => {
        "baseurl" => "http://nas.service.couchbase.com/builds/latestbuilds/couchbase-server/magma-preview/latest",
        "version" => "magma-preview"
    }
} end

mapping "region_mapping" do {
    "EC2 Oregon (us-west-2)" => {
        "datacenter" => "us-west-2a",
        "cloudnum" => "6",
        "cloud" => "EC2 us-west-2",
    },
    "EC2 Nor Cal (us-west-1)" => {
        "datacenter" => "us-west-1a",
        "cloudnum" => "3",
        "cloud" => "EC2 us-west-1",
    },
    "EC2 Virginia (us-east-1)" => {
        "datacenter" => "us-east-1b",
        "cloudnum" => "1",
        "cloud" => "EC2 us-east",
    },
    "EC2 Singapore (ap-southeast-1)" => {
        "datacenter" => "ap-southeast-1a",
        "cloudnum" => "4",
        "cloud" => "AWS ap-southeast-1",
    },
    "EC2 Ireland (eu-west-1)" => {
        "datacenter" => "eu-west-1a",
        "cloudnum" => "2",
        "cloud" => "EC2 eu-west-1",
    },
    "az_list" => {
        "EC2 Oregon (us-west-2)" => ["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"],
        "EC2 Nor Cal (us-west-1)" => ["us-west-1a", "us-west-1c"],
        "EC2 Virginia (us-east-1)" => [ "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"],
        "EC2 Singapore (ap-southeast-1)" => ["ap-southeast-1a", "ap-southeast-1b","ap-southeast-1c"],
        "EC2 Ireland (eu-west-1)" => ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
    }
} end

mapping "security_group_mapping" do {
    "true" => {
        "security_group" => "all_ports_open",
    },
    "false" => {
        "security_group" => "secure",
    },
    "default" => {
        "security_group" => "default",
    },
}
end


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
output "auto_stop" do
    label "Reminder:"
    category "Demo"
    default_value "This environment will stop automatically each night.  Click the \"Next Action\" and \"Cancel\" to cancel.  Press \"start\" to restart."
end

#########
# Resources
#########


resource 'eip', type: 'ip_address' do
    name "Couchbase"
    cloud map($region_mapping, $region, "cloud")
    domain "vpc"
end

resource 'volume', type: 'volume' do
    name "Couchbase"
    cloud map($region_mapping, $region, "cloud")
    datacenter map($region_mapping, $region, "datacenter")
    volume_type find("gp2")
end

resource 'server', type: 'server' do
    cloud map($region_mapping, $region, "cloud")
    datacenter map($region_mapping, $region, "datacenter")
    subnets "VPC"
    security_groups map($security_group_mapping, $security_group, "security_group")
    instance_type 'm4.xlarge'
    ssh_key 'Perry_Couchbase'
    server_template find('Couchbase Self-Service Template 5.0', revision: 0)
    cloud_specific_attributes do {
        "automatic_instance_store_mapping" => "true",
        "associate_public_ip_address" => "false",
        "root_volume_type_uid" => "standard"
    } end
end


resource 'node', type: 'server' do
    cloud map($region_mapping, $region, "cloud")
    datacenter map($region_mapping, $region, "datacenter")
    subnets "VPC"
    security_groups map($security_group_mapping, $security_group, "security_group")
    instance_type 'm4.xlarge'
    ssh_key 'Perry_Couchbase'
    multi_cloud_image_href map($os_mapping, $os, "mci_href")
    cloud_specific_attributes do {
        "automatic_instance_store_mapping" => "true",
        "associate_public_ip_address" => "false",
        "root_volume_type_uid" => "standard"
    } end
end

resource 'node_spot', type: 'server' do
    like @node
    cloud_specific_attributes do {
        "automatic_instance_store_mapping" => "true",
        "associate_public_ip_address" => "false",
        "root_volume_type_uid" => "standard",
        "pricing_type" => "spot",
        "max_spot_price" => '2.00',
    } end
end

resource 'cb_node', type: 'server' do
    like @node
    name 'Couchbase Server 4.5'
    server_template find('Couchbase Server 4.0 - Self-Service', revision: 20)
    inputs do {
        'CB_CLUSTERING' => 'text:TRUE',
    } end
end

resource 'cb_server_node', type: 'server' do
    like @cb_node
end
resource 'cb_sg_node', type: 'server' do
    like @cb_node
end

resource 'app_node', type: 'server' do
    like @node
    name "Application Node"
    inputs do {
        'CB_INSTALL' => 'text:FALSE',
    } end
    server_template find('CBSClient 4.0 Travel App', revision: 20)
end

resource 'cb_node_spot', type: 'server' do
    like @node_spot
    name 'Couchbase Server 4.5'
    server_template find('Couchbase Server 4.0 - Self-Service', revision: 20)
    inputs do {
        'CB_CLUSTERING' => 'text:TRUE',
    } end
end

resource 'app_node_spot', type: 'server' do
    like @node_spot
    name 'zApp_node'
    server_template find('CBSClient 4.0 Travel App', revision: 20)
end


#########
# Operations/Definitions
#########

##### operation start #######
operation 'start' do
    definition 'start'
end
define start() do
    if !$$all_started
        $$all_started = true

        concurrent foreach @server in @@deployment.servers() on_error: skip do
            if @server.state == 'provisioned'
                @server.current_instance().start()
                sleep_until(@server.state == 'operational')
            end
        end
    end
end
############################

##### operation stop #######
operation 'stop' do
    definition 'stop'
end
define stop() do
    if !$$all_stopped
        $$all_stopped = true

        concurrent foreach @server in @@deployment.servers() on_error: skip do
            if @server.state == 'operational'
                @server.current_instance().stop()
                sleep_until(@server.state == 'provisioned')
            end
        end
    end
end
############################

##### operation enable #######
operation 'enable' do
    definition 'generated_enable'
end

define generated_enable($shutdown) do
    call get_current_user_timezone() retrieve $tz
    $end_time = now() + ($shutdown * 60)
    $monthly = now() + 2629744
    @@execution.patch(ends_at: $end_time)
    call log("Set auto-terminate to: " + to_s($shutdown) + " minutes from now")

    rs_ss.scheduled_actions.create(execution_id: @@execution.id, action: "terminate", first_occurrence: $monthly, timezone: $tz, recurrence: "FREQ=MONTHLY;")
    call log("Set monthly auto-terminate")

    rs_ss.scheduled_actions.create(execution_id: @@execution.id, action: "stop", first_occurrence: "2016-01-01T00:00:00+00:00", timezone: $tz, recurrence: "FREQ=DAILY;")
    call log("Set daily auto-stop")
end
############################

##### operation terminate #######
operation 'terminate' do
    definition 'terminate'
end
define terminate() do
    if !$$all_terminated
        $$all_terminated = true
        @servers = @@deployment.servers()
        sub on_error: skip do
            @servers.terminate()#delete(@servers)
#            if $_error != null
#                handle_error("(1) Terminating due to error: " + to_s($_error["message"]) + "\nCheck here for outage status: http://status.rightscale.com/.  \nPerhaps try a new Amazon region and/or instance type.\n\n\n ")
#            end
        end
    end
end
############################
define handle_timeout($task) do
    call log("Timeout Handled from: " + to_s($task))
    #raise "Launch timeout. Try increasing timeout length, check outage status: http://status.rightscale.com/ or use a different AWS region/instance type.  Email perry@couchbase.com for more details.\n"
end

define handle_error($error) do
    #call log("Handle Error called:\n"+to_s($error)+"\n"+ inspect($_error))

  #    if $$error_handled
  #
  #    end

  $$error_handled = true

  $error_string = ""
  if ($error)
    $error_string = $error_string + $error
  end
  if ($_error)
    $error_string = $error_string + " "+ to_s($_error["message"]) #+ "\nOrigin:\n\t"+to_s($_error["origin"])
  end

  $message = ""
  if ( $error_string =~ "InsufficientResourceCapacity" )
    $message = "Insufficient Capacity in AWS region for specific instance type, try a different AWS region/instance type.\n"
  end
  if ( $error_string =~ "This server does not have sufficient memory to support requested memory quota." )
    $message = "Insufficient memory to support requested memory quota.  Please check for mismatched instance types per service.\n"
  end

  $str_to_raise = $message + $error_string;

  call log("Raising Error:\n" + $str_to_raise)

#     concurrent do
#         sub on_error: skip do
#             @servers = @@deployment.servers()
#             @servers.delete()
#         end
#            @@execution.terminate()
  sub  task_label: "Error Detected: Terminating Instances", on_error: skip do
    @@deployment.servers().terminate()
  end
  raise $str_to_raise
#    end
  cancel
  call log("Shouldn't be here")
end

define cancel() do
    call log("Cancel called:"+to_s($_error))

    if !$$all_canceled
        $$all_canceled = true

        $_error = $_error
        if $_error != null
            call handle_error("(3) App Canceled: "+to_s($_error["message"]))
        end
        cancel # Cancels all tasks in the entire process
    end
end
define log($message) do
    if size($message) > 250
        rs_cm.audit_entries.create(notify: "None", audit_entry: {auditee_href: @@deployment.href, summary: split($message, ":")[0], detail: to_s($message)})
        else
        rs_cm.audit_entries.create(notify: "None", audit_entry: {auditee_href: @@deployment.href, summary: to_s($message), detail: to_s($message)})
    end
end

define validate_port($cluster_port) do
    if $cluster_port == 4369 || ($cluster_port >= 8092 && $cluster_port <= 8094) || ($cluster_port >= 9100 && $cluster_port <= 9105) || $cluster_port == 9998 || $cluster_port == 9999 || ($cluster_port >= 11209 && $cluster_port <= 11211) || $cluster_port == 11214 || $cluster_port == 11215 || ($cluster_port >= 18091 && $cluster_port <= 18093) || ($cluster_port >= 21100 && $cluster_port <= 21299)

        call handle_error("UI Port is invalid.  Must be >1023, <65536 and not: 4369, 8092 to 8094, 9100 to 9105, 9998, 9999, 11209 to 11211, 11214, 11215, 18091 to 18093, and 21100 to 21299")
    end
end

define get_url($os_mapping, $os, $version, $cburl) return $url do
    #full url =                        <base_url>                                                      / <version url>   / <couchbase-server-enterprise>   <del>    <version/build url>            <os>
    #https://s3.amazonaws.com/packages.couchbase.com/releases/5.5.0-beta/couchbase-server-enterprise-5.5.0-beta-centos7.x86_64.rpm
    #https://s3.amazonaws.com/packages.couchbase.com/releases/5.1.1/couchbase-server-enterprise_5.1.1-debian9_amd64.deb
    #http://nas.service.couchbase.com/builds/latestbuilds/couchbase-server/vulcan/2954/couchbase-server-enterprise-5.5.0-2954-centos7.x86_64.rpm
    #http://nas.service.couchbase.com/builds/latestbuilds/couchbase-server/vulcan/latest/couchbase-server-enterprise-vulcan-centos7.x86_64.rpm

    $version_url = map($os_mapping, $version, "version")
    $base_url = map($os_mapping,$version,"baseurl")
    $build_url = map($os_mapping,$version,"build")
    $delimeter_url = map($os_mapping,$os,"del")
    $os_url = map($os_mapping,$os,"os")

    if $base_url =~ "s3.amazonaws.com"
        $url = join([$base_url, $version_url, "/couchbase-server-enterprise", $delimeter_url, $version_url, $os_url])
    end

    if $base_url =~ "nas.service.couchbase.com"
        $url = join([$base_url, $build_url, "/couchbase-server-enterprise", $delimeter_url, $version_url, "-",$build_url, $os_url])
    end

    if $version =~ "latest"
        $url = join([$base_url, "/couchbase-server-enterprise", $delimeter_url, $version_url, $os_url])
    end

    if $cburl != ""
        $url = $cburl
    end
end

define get_sg_url($os_mapping, $os, $sg_version, $sg_url) return $url do
    #full url =                        <base_url>                                                      / <version url>   / <couchbase-server-enterprise>   <del>    <version/build url>            <os>
    #eg: <https://s3.amazonaws.com/packages.couchbase.com/releases>                                    /  4.5.0-beta     /  couchbase-server-enterprise    [- _]    4.5.0-beta      -centos6.x86_64.rpm
    #eg: <http://couchbase:north$cale@nas.service.couchbase.com/builds/latestbuilds/couchbase-server>  /  watson/2600    /  couchbase-server-enterprise    [- _]    4.5.0-2600      -centos6.x86_64.rpm

    $version_url = map($os_mapping, $sg_version, "sg_version")

    $url = join([map($os_mapping,$sg_version,"baseurl"), $version_url, "/couchbase-sync-gateway-enterprise",map($os_mapping,$os,"del"),$version_url,map($os_mapping,$os,"os")])

    if $sg_url != ""
        $url = $sg_url
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

define launch_cluster($groups, $node_hash, $url, $indexstorage, @eip) return $cluster_ip, $ips, $dns do

    $ips = []
    $dns = []
    $cluster_ip = ''
    $error = ''

    $clustered=false;
    $datanodes=0;
    $rebalance_count = 0;
    $mds = false;

    foreach $group in $groups do
        if $group['nodes'] > 0
            if $group['clustered'] == "true"
                $clustered = true
                $rebalance_count = $rebalance_count + $group['nodes']

                if $group['data'] != "true" || $group['query'] != "true" || $group['index'] != "true" || $group['fts'] != "true" || $group['analytics'] != "true" || $group['eventing'] != "true"
                    $mds = true;
                end

                if $group['data'] == "true"
                    $datanodes = $datanodes + 1
                end

                call log("Cluster and Services check:" + to_s($group))
                if $group['data'] == "false" & $group['query'] == "false" & $group['index'] == "false" & $group['fts'] == "false" & $group['analytics'] == "false" & $group['eventing'] == "false"
                    call handle_error("Must select at least one service for a \"clustered\" node")
                end

                call log("Version/service compatibility check: "+to_s($url)+" "+to_s($group))
                if $url =~ "-4." || $url =~ "_4."
                    if $group['fts'] == "true" || $group['analytics'] == "true" || $group['eventing'] == "true"
                      call handle_error("FTS, Analytics or Eventing not supported in version 4.x")
                    end
                end
                if $url =~ "-5.0" || $url =~ "_5.0" || $url =~ "-5.1" || $url =~ "_5.1"
                    if $group['analytics'] == "true" || $group['eventing'] == "true"
                        call handle_error("Analytics or Eventing not suported before 5.5")
                    end
                end
            end

        end
    end

call log("Data node in cluster check: " + to_s($clustered) + " " + to_s($datanodes))
if $clustered == true && $datanodes == 0
  call handle_error("Must have at least one data node in a cluster, please disable clustering or change the services topology and relaunch")
end

call log("CE memopt/mds check: " + to_s($url) + " " + to_s($indexstorage) + " " + to_s($mds))
if $url =~ "community"
  if $indexstorage =~ "memopt"
    call handle_error("Cannot use memopt with CE")
  end

  if $mds == true
    call handle_error("Cannot use MDS with CE")
  end
end



sub task_label: "Launching " + $rebalance_count + " Node Cluster:" do

  @cluster = concurrent map $group in $groups return @instances on_error : handle_error("Cluster Launch Error") do
    if $group['nodes'] > 0
      if $group['clustered'] == "false"
        $group['services'] = "Blank"
        $node_hash['fields']['inputs']['CB_CLUSTERING'] = 'text:FALSE'
        $node_hash['fields']['inputs']['CB_SERVER_CLUSTER'] = 'text:FALSE'
      else
        if $group['data'] == "true"
          $group['services'] = $group['services'] + "data,"
        end
        if $group['query'] == "true"
          $group['services'] = $group['services'] + "query,"
        end
        if $group['index'] == "true"
          $group['services'] = $group['services'] + "index,"
        end
        if $group['fts'] == "true"
          $group['services'] = $group['services'] + "fts,"
        end
        if $group['analytics'] == "true"
          $group['services'] = $group['services'] + "analytics,"
          $node_hash['fields']['inputs']['CB_SERVER_ANALYTICS_DISK'] = "text:TRUE"
        end
        if $group['eventing'] == "true"
          $group['services'] = $group['services'] + "eventing"
        end
      end

      if $group['disk'] < 0
        $node_hash['fields']['inputs']['CB_SERVER_EPHEMERAL_DISK'] = "text:TRUE"
      end

      $node_hash['fields']['inputs']['CB_SERVER_DISK'] = "text:" + $group['disk']
      $node_hash['fields']['inputs']['CB_SERVICES'] = "text:" + $group['services']
      $node_hash['fields']['name'] = "Couchbase Server " + $group['services']
      $node_hash['fields']['inputs']['CB_REBALANCE_COUNT'] = "text:" + $rebalance_count
      if $group['az'] != ""
        @datacenter = find("datacenters", {name: $group['az'], cloud_href: @cloud.href})
        $node_hash['fields']['datacenter_href'] = @datacenter.href
      end

      call log($group['name'] + " Node hash: " + to_s($node_hash))

      $error = "failed to launch_nodes"
      call launch_instances($group['name'] + ": " + $group['services'], $group['nodes'], $group['instance'], $group['disk'], $node_hash, @eip, $volume_hash, @cloud) retrieve @instances

    end
  end

  @cluster = @cluster.get()

  foreach @node in @cluster do
  $dns << @node.public_dns_names[0]
  $ips << @node.public_ip_addresses[0]
end
$cluster_ip = $ips[0]

  #call log("Launched: " + to_s($groups) + ": Cluster IP: " + to_s($cluster_ip) + "All IPs/DNS:" + to_s($ips) + ", " + to_s($dns))

end
end

define launch_instances($name, $number, $instance_type, $disksize, $node_hash, @eip, $volume_hash, @cloud) return @allnodes do

    $error = ''
    sub task_label:"Launching "+to_s($number)+" "+$name+" Nodes" do
        if $number > 0
            $partial = 0
#            if index($name, "Blank") || index($name, "App")
#                $partial = 1
#                call log("Starting a partial launch of " + to_s($number) + " " + $name + " nodes")
#            else
                call log("Starting to launch " + to_s($number) + " " + $name + " nodes")
#            end
#
            if !($disksize)
                $disksize = 0
            end
            @allnodes = rs_cm.servers.empty();
            @allnodes = concurrent map $item in [1..$number] return @instance on_error: handle_error("Instance Launch Error:") do
                #call log("disk size is " + $disksize )
                concurrent return @server,@eip,@volume do
                    call create_server($node_hash, $instance_type, @cloud) retrieve @server task_label: "Creating Server", on_error: handle_error("Server Launch Error:")
                    sub task_label: "Provisioning EIP", on_error: handle_error("EIP Provision Error:") do
                            provision(@eip)
                    end
                    sub  task_label: "Provisioning Volume", on_error: handle_error("Volume Provision Error:") do
                        if( $disksize > 0)
                            $volume_hash['fields']['size'] = to_s($disksize)
                            @volume = $volume_hash
                            provision(@volume)
                        end
                    end
                end
                call log("#" + to_s($item) + " " + $name + " server created, EIP and volume provisioned")

                if !empty?(@eip)
                    sub task_label: "Creating EIP Binding" do
                        @eip.ip_address_bindings().create(instance_href: @server.next_instance().href, public_ip_address_href: @eip.href)
                    end
                    call log("#" + to_s($item) + " " + $name + " EIP bound")
                end

                if( $disksize > 0)
                    sub task_label: "Creating Volume Attachment" do
                        @volume.recurring_volume_attachments().create(recurring_volume_attachment: {"device": "/dev/sdp", "runnable_href": @server, "storage_href": @volume})
                    end
                    call log("#" + to_s($item) + " " + $name + " " + $disksize + "GB volume attached")
                end

                call launch_server(@server, $name, $partial) retrieve @instance, task_label: "Launching Server"
                call log("#" + to_s($item) + " " + $name + " server launched, partial="+$partial)

                if !empty?(@eip)
                    $address = @eip.address
                    sleep_until( @instance.public_ip_addresses[0] == $address )
                end
                @instance = @instance.get()
                sleep_until( size(@instance.public_dns_names[0]) > 0 )
                call log("#" + to_s($item) + " " + $name + " IP and DNS discovered: EIP: " + to_s($address) + ", From instance: " + to_s(@instance.public_ip_addresses[0]) + ", " + to_s(@instance.public_dns_names[0]))
            end

            call log("Finished concurrent map launching " + to_s($number) + " node (" + $name + ")")
        end
    end
end

define launch_nodes($name, $number, $instance, $disksize, $node_hash, @eip, $volume_hash, @cloud) return $ips, $dns do
call launch_instances($name, $number, $instance, $disksize, $node_hash, @eip, $volume_hash, @cloud) retrieve @all_nodes
$dns = []
$ips = []
foreach @node in @all_nodes do
$dns << @node.public_dns_names[0]
$ips << @node.public_ip_addresses[0]
end
call log("IPs ready for " + to_s($number) + " " + to_s($name) + " nodes: " + to_s($ips) + ", " + to_s($dns))
end

define launch_server(@server, $name, $partial) return @instance do

$error = ''
# keep server name in case of error where @server is invalid
$server_name = to_s(@server.name)
$server_href = to_s(@server.href[])

@instance = rs_cm.instances.empty()

sub task_label: 'Tagging', on_error: handle_error("Tagging Error:") do
  $tags = [join(["ec2:rs_deployment=", @@deployment.name]), join(["ec2:server_href=", @server.href[]])]
  call log("Adding Tag: " + to_s($tags) + " to: " + to_s(@server.href[]))

  $error = "failed to multi_add"
  rs_cm.tags.multi_add(resource_hrefs: @server.href[], tags: $tags)
  call log("Added Tag: " + to_s($tags) + " to: " + to_s(@server.href[]))
  task_label('Done adding tags')
end
call log("Launching: " + $server_name)

sub on_error: servers_handle_launch_failure(@server) do
  @instance = @server.launch()
end
call log("Done Launching: " + $server_name)

#@server.launch()
$final_state = "launching"
sub task_label: 'Waiting for node to boot', on_error: skip do

  #sleep_until @server.state =~ "^(operational|stranded|stranded in booting|stopped|terminated|inactive|error)$"
  if $partial == 1
    $wake_condition = "^(booting|operational|stranded in booting|stopped|provisioned|terminated|terminating|inactive|error)$"
  else
    $wake_condition = "^(operational|stranded in booting|stopped|provisioned|terminated|terminating|inactive|error)$"
  end
  call log("Waiting for boot: " + $server_name)
  sleep_until (@server.state =~ $wake_condition)
  call log("Done booting: " + $server_name)
  $final_state = @server.state
end

if ($final_state =~ /^(operational|booting)$/)
  @server = rs_cm.get(href: @server.href) # full refresh
  @instance = @server.current_instance()
else
  call log("Error Detected: " + $server_name)
  call get_error_audits(@instance) retrieve $detailed_message

  $error = "Failed to provision server. Expected state 'operational' or 'booting' but got '" + to_s($final_state) + "' for server: " + to_s($server_name) + " / Href: " + to_s($server_href)
  if size($detailed_message) > 0
    $error = $error + "\nPotential Errors:\n" + to_s($detailed_message)
  end

  call log("Error logs retrieved: " + $server_name)
#        concurrent do
#            # Update the @server collection before trying to delete so we have updated state.
#            sub task_name: "wait", task_label: "Deleting Server:" do
#                call log("Delete called: "+$server_name)
#                call rs__cwf_servers_delete(@server.get())
#                call log("Delete finished: "+$server_name)
#            end
#            sub do
#         concurrent do
#                sub do
        call log("Calling Handle Error For: "+$server_name)
        call handle_error($error)
#                end
#                abort_task

#        end
    end
end

define create_server($node_hash, $instance, @cloud) return @server do
    if $instance != ''
        $node_hash['fields']['instance_type_href'] = to_s(find("instance_types", { name: $instance, cloud_href: @cloud.href }))
    end

    $fields = $node_hash['fields']
    @server = rs_cm.servers.create($fields)
end

define servers_handle_launch_failure(@server) do
    $error = ''
    $server_name = @server.name

    concurrent return $detailed_message do
        call get_error_audits(@server) retrieve $detailed_message

        sub on_error: skip do
            call rs__cwf_terminate(@server)
        end
    end

    call rs__cwf_simple_delete(@server)

    $error = "Error trying to launch server (" + $server_name + ")"
    if $_errors && $_errors[0] && $_errors[0]["response"]
        $error = $error + ": " + $_errors[0]["response"]["body"]
    end
    if size($detailed_message) > 0
        $error = $error + "\nPotential Errors:\n" + $detailed_message
    end
    call handle_error($error)
end

define get_error_audits(@resource) return $error_audits do
    # The string to return
    $error_audits = ""

    # Get all audit entries in the past 10 minutes (can't filter on terminated instance hrefs, so we do filtering client-side)
    call log("Get Error Audits: Started")
#    $start_time = strftime(now()-(60*10), "%Y/%m/%d %H:%M:%S +0000")
#    $end_time = strftime(now(), "%Y/%m/%d %H:%M:%S +0000")
#    @audits = rs_cm.audit_entries.get(start_date: $start_time, end_date: $end_time, limit: 999)
    $start_time = strftime(now()-(60*10), "%Y/%m/%d %H:%M:%S +0000")
    $end_time = strftime(now(), "%Y/%m/%d %H:%M:%S +0000")
    @audits = rs_cm.audit_entries.get(start_date: $start_time, end_date: $end_time, limit: 999,filter: ["auditee_href=="+ @resource.href])
    call log("Get Error Audits: Retrieved")
    # Can't filter on auditee_href above because of CM-1037
    # Can't use select cause the href is buried
    # Can't call @audit.auditee() because of CM-1037
    # Filter all those audits to find those that apply to this resource
#    @filtered_audits = rs_cm.audit_entries.empty()
#    foreach @audit in @audits do
#        $audits = to_object(@audit)
#        $audit = $audits['details'][0]
#        if size(select($audit['links'], {"href": @resource.href})) > 0
#            @filtered_audits = @filtered_audits + @audit
#        end
#    end
#    @audits = @filtered_audits

    # Find audits with the words failed or stranded in the summary
    @audits = select(@audits, { "summary": /(failed|stranded)/i })
    foreach @audit in @audits do
        call log("Get Error Audits: Finding (1)")
        # Get the AE details
        $detail = @audit.detail()
        #call log("Get Error Audits: Finding (2)")
        $detail = $detail[0]
        # TODO need to get 'text' if it's a script failure, otherwise don't? maybe?
        #$detail = to_s($audit_detail[0]["text"])

        # If the summary has "Instance: failed", the whole detail message is probably 1 line and is useful
        #call log("Get Error Audits: Finding (3)")
        if @audit.summary =~ /Instance: failed/i
            $error_audits = $error_audits + "\n    " + $detail
        end
        #call log("Get Error Audits: Finding (4)")
        # If the summary is "stranded" or "boot failed", it likely contains the boot scripts logs, so
        # search through the logs and look for interesting lines
        if @audit.summary =~ /(stranded|boot failed)/i
            $lines = lines($detail)
            #call log("Get Error Audits: Finding (5)")
            foreach $line in $lines do
                #call log("Get Error Audits: Finding (6)")
                $script_line = ""
                # Save the name of the script
                if index($line, /RS>.*(RightScript:|Running recipe).*$/)
                    $script_line = $line
                end
                # Look for some keywords in the line
                if index($line, /(error|failed|exited with code [1-9]+)/i)
                    # If there is a script name we haven't printed yet, print it
                    if size($script_line) > 0
                        $error_audits = $error_audits + "  " + $script_line
                        $script_line = ""
                    end
                    $error_audits = $error_audits + "    " + $line
                end
            end
        end
    end
    call log("Get Error Audits: Done")
end
