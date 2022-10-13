#! /bin/bash -x

if [[ $EUID -ne 0 ]]; then
  exec sudo "$0"
fi

shopt -s nocasematch
shopt -s expand_aliases
exec &> >(tee -ia /var/log/couchbase_right_script.log)

alias echo='{ save_flags="$-"; set +x;} 2> /dev/null; echo_and_restore'
echo_and_restore() {
        builtin echo "$*"
        case "$save_flags" in
         (*x*)  set -x
        esac
}

echo "Running Couchbase Server Script:"
echo `date`

function add_tag {
  if `rs_tag -h > /dev/null`; then
    tag=`rs_tag -a $1`    
  elif `/usr/local/bin/rsc -h > /dev/null`; then
    #    tag=`/usr/local/bin/rsc --rl10 cm15 multi_add /api/tags/multi_add resource_hrefs[]=$RS_SELF_HREF tags[]=$1`
    # Obtain instance HREF
    instance_href=$(/usr/local/bin/rsc --retry=5 --timeout=60 --rl10 cm15 \
        index_instance_session /api/sessions/instance --x1 ':has(.rel:val("self")).href')
    
    # Adding tag
    /usr/local/bin/rsc --retry=5 --timeout=60 --rl10 cm15 multi_add /api/tags/multi_add \
        "resource_hrefs[]=$instance_href" \
        "tags[]=$1"
  else
    echo "Can't add tags"
    exit -1
  fi
  
  if [[ "$tag" =~ "failed" ]]; then
    echo "failed: Error setting tags, exiting"
    exit -1;
  fi
}

function get_by_tag {
  tags=""
  
  if  `rs_tag -h > /dev/null`; then
    tags=`rs_tag -q $1`
  elif `/usr/local/bin/rsc -h > /dev/null`; then  
    #instances=`/usr/local/bin/rsc --rl10 cm15 by_tag /api/tags/by_tag resource_type=instances tags[]=$1 | tr , \\\n | egrep -o '/api.*?"' | cut -d '"' -f1`
    instances=`/usr/local/bin/rsc --retry=5 --timeout=60 --rl10 cm15 by_tag /api/tags/by_tag resource_type=instances tags[]=$1 | \
      tr , \\\n | egrep -o '/api.*?"' | cut -d '"' -f1`

    while read instance; do
      tags="$tags
      `/usr/local/bin/rsc --rl10 cm15 by_resource /api/tags/by_resource resource_hrefs[]=$instance --xm .name | \
      egrep -o \"$1.*?\" | \
      cut -d '"' -f1 \
      `"
    done <<< "$instances"
  else
    echo "failed: Can't get tags"
    exit -1
  fi

  if [[ "$tags" =~ "failed" ]]; then
    echo "failed: Error setting tags, exiting"
  else
    private_ips=`echo "$tags" | grep -i "$1=" | cut -d '=' -f 2 | cut -d '"' -f 1 | sort | cut -d '-' -f2-`
    echo "$private_ips"
  fi
}

function remove_tag {
  if  `rs_tag -h > /dev/null`; then
    rs_tag -r $1
  elif `/usr/local/bin/rsc -h > /dev/null`; then
    #/usr/local/bin/rsc --rl10 cm15 multi_delete /api/tags/multi_delete resource_hrefs[]=$RS_SELF_HREF tags[]=$1
    # Obtain instance HREF
    instance_href=$(/usr/local/bin/rsc --retry=5 --timeout=60 --rl10 cm15 \
      index_instance_session /api/sessions/instance --x1 ':has(.rel:val("self")).href')

    # Delete tag
    /usr/local/bin/rsc --retry=5 --timeout=60 --rl10 cm15 multi_delete /api/tags/multi_delete \
      "resource_hrefs[]=$instance_href" \
      "tags[]=$1"
  else
    echo "failed: Can't remove tags"
    exit -1
  fi
}

function rebalance {
    if [[ "$CB_REBALANCE_COUNT" == "" ]]; then
        CB_REBALANCE_COUNT=0
    fi

    echo "Checking whether we want to rebalance..."
    
    known_hosts=`/opt/couchbase/bin/couchbase-cli server-list -c localhost:$CB_UI_PORT -u $CB_USER -p $CB_PASS`
    known_hosts=`echo "$known_hosts" | grep "healthy" | wc -l`
    
    if [ "$known_hosts" -ge "$CB_REBALANCE_COUNT" ]; then
        while [[ ! $(/opt/couchbase/bin/couchbase-cli rebalance-status -u $CB_USER -p $CB_PASS -c localhost:$CB_UI_PORT | grep -i "notRunning") ]] ; do
           echo "Rebalance already running, sleeping and will try again."
           sleep 5
        done

        echo "Rebalancing since there are at least $CB_REBALANCE_COUNT nodes in the cluster."
        
        add_tag "rebalance:$righttag=`date -u +%H%M%S%3N`-`echo "$nodename"`"
        
        echo "Checking for other rebalancers"
        private_ips=$(get_by_tag "rebalance:$righttag")
        private_ips=`echo "$private_ips"  | cut -d ';' -f1` #to remove services
        position=`echo "$private_ips" | grep -o -b "$nodename" | cut -d ':' -f 1`;
    
        if [ "$position" == "0" ]; then
          echo "I am the first to rebalance"
          wget -q -O- --user=$CB_USER --password=$CB_PASS --post-data='ns_config:set(rebalance_moves_per_node, 8).' http://localhost:$CB_UI_PORT/diag/eval > /dev/null;

          rebalance=`/opt/couchbase/bin/couchbase-cli rebalance -u $CB_USER -p $CB_PASS -c localhost:$CB_UI_PORT`
          echo "Rebalance: $rebalance"

          while [[ $(curl -u $CB_USER:$CB_PASS http://localhost:$CB_UI_PORT/pools/default/tasks | grep -i "Rebalance failed") ]]; do
            echo "Rebalance failed, trying again"
            rebalance=`/opt/couchbase/bin/couchbase-cli rebalance -u $CB_USER -p $CB_PASS -c localhost:$CB_UI_PORT`
            echo "Rebalance: $rebalance"
            sleep 5;
          done        

          echo "Rebalance completed successfully."
        else
          echo "Another node will rebalance first"
          exit 0
        fi
    else
        echo "Skipping rebalance since there are only $known_hosts nodes in the cluster"
        exit 0
    fi
}


#####Main Execution

if [[ -e /root/.couchbase/cb_server ]]; then 
  echo "Just start couchbase-server:"
  x=`service couchbase-server start`
  if [[ "$x" =~ "FAIL" ]]; then
    echo "Error starting, sleep 5 and then start again:"
    sleep 5
    x=`service couchbase-server start`
  fi
  exit 0;
else
  mkdir -p /root/.couchbase/cb_server
fi

####Downloading CB Server Package
if  [[ "$CB_SERVER_INSTALL" == "FALSE" ]]; then
  echo "Don't want to install Couchbase Server"
  exit 0 # Leave with a smile ...
fi
righttag=`echo $CB_CLUSTER_TAG | sed s/\ /_/`

add_tag "couchbase_server:$righttag=installed"

x=`echo "$CB_SERVER_URL" | rev | cut -d'/' -f1 | rev`
echo "Downloading file: $x from $CB_SERVER_URL"

cd /root
curl -fqsLO $CB_SERVER_URL
 
if [ ! -e $x ] 
then
  curl -fqsLO --user 'couchbase:YAN3FrT7k' $CB_SERVER_URL
fi

if [ ! -e $x ] 
then
  echo "Failed to download $x"
  exit -1
fi

####Installing CB Server Package
echo "Installing file: $x"  
if [[ "$x" =~ "rpm" ]]
then 
  install=`yum install -y "$x"`
else
  install=`dpkg -i "./$x"`
fi

if [[ "$install" =~ "error" ]]
then
  echo "Failed to install $x: $install"
fi

chown -R couchbase:couchbase /couchbase/

####Clustering
if  [[ "$CB_SERVER_CLUSTER" == "FALSE" ]]; then
  echo "Don't want to cluster Couchbase Server"
  exit 0 # Leave with a smile ...
fi

echo "Running Clustering Script"

if [ -e "/var/spool/cloud/user-data/RS_EIP" ]
then
  echo "Found EIP: `cat /var/spool/cloud/user-data/RS_EIP`, setting to `host \`cat /var/spool/cloud/user-data/RS_EIP\` | cut -d ' ' -f 5 | sed s/.$//`"
  nodename=`host \`cat /var/spool/cloud/user-data/RS_EIP\` | cut -d ' ' -f 5 | sed s/.$//`
else
  nodename=`curl http://169.254.169.254/latest/user-data | grep expected_public_ip | cut -d"'" -f 2`
  nodename=`nslookup $nodename |  egrep -o ec2.* | sed s/com\\\./com/`
fi

if [ "$EIP" != 0 ]; then
  echo "Using externally supplied IP address: $EIP"
  nodename=$EIP
  nodename=`nslookup $nodename |  egrep -o ec2.* | sed s/com\\\./com/`
fi

if [ ${#nodename} == 0 ]; then
  echo "Still don't have a node name, using ec2 public"
  nodename=`curl http://169.254.169.254/latest/meta-data/public-hostname`
fi

CB_SERVICES=`echo "$CB_SERVICES" | sed '$s/,$//'`

version=`cat /opt/couchbase/VERSION.txt | cut -d '-' -f 1`
major_ver=`echo "$version" | cut -d '.' -f 1`
minor_ver=`echo "$version" | cut -d '.' -f 2`
ramsize=$CB_RAMSIZE

if [[ "$ramsize" == "" ]]; then
    ramsize=`echo "\`free -m | grep Mem| awk '{print $2}'\` * .8" | bc -l | cut -d'.' -f 1`
fi

dataramquota=$(( ( ramsize * 3 ) / 4 ));
indexramquota=$(( ( ramsize * 1 ) / 4 ));

if [ "$dataramquota" -lt "1000" ]; then
  dataramquota=1000
fi

if [ "$indexramquota" -lt "256" ]; then
  indexramquota=256
fi


echo "Setting disk paths, hostname to: $nodename :"
mkdir -p /couchbase/data
mkdir -p /couchbase/index
chown -R couchbase:couchbase /couchbase/
  
  #couchbase-cli node-init --node-init-analytics-path /dbpath1 \
opts=""
if [[ "${CB_SERVICES,,}" =~ "analytics" ]]; then
  if [[ -e /tmp/couchbase/analytics_devices ]]; then
    for i in `cat /tmp/couchbase/analytics_devices`; do
      opts="$opts --node-init-analytics-path $i"
    done
  fi
fi

while [[ $(/opt/couchbase/bin/couchbase-cli node-init -c localhost:8091 -u $CB_USER -p $CB_PASS \
        --node-init-hostname=$nodename --node-init-data-path=/couchbase/data --node-init-index-path=/couchbase/index \
        $opts | grep -i "error") ]]; do
  sleep 2;
done

echo "Setting my own tag to $righttag:"
#date=`date -u +%H%M%S%3N`
#add_tag "couchbase:$righttag=$date-$nodename;$CB_SERVICES"
add_tag "couchbase:$righttag=`date -u +%H%M%S%3N`-$nodename;$CB_SERVICES"

while true; do
    echo "Checking whether I am clustered already:"
    known_hosts=`/opt/couchbase/bin/couchbase-cli server-list -c localhost:$CB_UI_PORT -u $CB_USER -p $CB_PASS | wc -l`
    if [ "$known_hosts" != 1 ]; then
        echo "I am already part of a cluster"
        break
    fi
    
    echo "Searching for other members of cluster: $righttag:"
    private_ips=$(get_by_tag "couchbase:$righttag")
    private_ips=`echo "$private_ips"  | cut -d ';' -f1` #to remove services

    if [[ "$private_ips" =~ "failed" ]]; then
      echo "Error querying tags, retrying"
      continue;
    fi

    position=`echo "$private_ips" | grep -o -b "$nodename" | cut -d ':' -f 1`;
    
    if [ "$position" == "0" ] || [ "$private_ips" == "" ]; then ##first or only node
      echo "I am the first or only node"
      i=0;
      while true; do
        echo "Starting my own cluster ($i):"
        if ! [[ $CB_SERVICES =~ "data" ]] ; then
          echo "First node must have data service, resetting tag and breaking out of loop"
          add_tag "couchbase:$righttag=`date -u +%H%M%S%3N`-$nodename;$CB_SERVICES"
          continue 2;
        fi                
        
        start=`/opt/couchbase/bin/couchbase-cli cluster-init -c localhost:8091 \
            --cluster-port=$CB_UI_PORT --cluster-username=$CB_USER --cluster-password=$CB_PASS --cluster-name="$CB_CLUSTERNAME" \
            --services=$CB_SERVICES --index-storage-setting=$CB_INDEX_MODE --cluster-ramsize=$dataramquota --cluster-index-ramsize=$indexramquota`
            
        echo "Tried to init node: $start"

        if [[ "$start" =~ "ERROR: insufficient memory" ]]; then
          echo "$start"
          echo "Trying again without lowest memory quotas:"
          start=`/opt/couchbase/bin/couchbase-cli cluster-init -c localhost:8091 \
            --cluster-port=$CB_UI_PORT --cluster-username=$CB_USER --cluster-password=$CB_PASS --cluster-name="$CB_CLUSTERNAME" \
            --services=$CB_SERVICES --index-storage-setting=$CB_INDEX_MODE --cluster-ramsize 256 --cluster-index-ramsize 256 --cluster-fts-ramsize 256 \
            --cluster-eventing-ramsize 256 --cluster-analytics-ramsize 1024`
          if [[ ! "$start" =~ "SUCCESS" ]]; then
            echo "Failed: $start"
            exit -1
          fi
        fi
        
        if [[ "$start" =~ "SUCCESS" ]]; then
          echo "Disabling index aware rebalance:";
          curl -u $CB_USER:$CB_PASS -X POST http://localhost:$CB_UI_PORT/internalSettings -d indexAwareRebalanceDisabled=true
          echo "Enabling HTTP access:";
          curl -u $CB_USER:$CB_PASS -X POST http://localhost:$CB_UI_PORT/internalSettings -d httpNodeAddition=true
#          echo "Turning off TLS, needed for >7.1"
#          curl -u $CB_USER:$CB_PASS -X POST http://localhost:$CB_UI_PORT/internalSettings/  -d httpNodeAddition=true

          break 2
        fi
        
        sleep 10;
        i=$((i+1))
      done 
    else  ##not first in position
      echo "Node list: $private_ips";
      while read ip; do
         echo "Attempting to join node: $ip:$CB_UI_PORT"
       
         join=`/opt/couchbase/bin/couchbase-cli server-add -c http://$ip:$CB_UI_PORT -p $CB_PASS -u $CB_USER \
            --server-add=$nodename:$CB_UI_PORT --server-add-username=$CB_USER --server-add-password=$CB_PASS \
            --services=$CB_SERVICES`
          
         if [[ "$join" =~ "added" ]]; then
             echo "Joined: $ip"
             break 2;
         elif [[ "$join" =~ "This server does not have sufficient memory to support requested memory quota." ]]; then
             echo "Fatal Join Error: $join.";
             exit -1;
         elif [[ "$join" =~ "Failed to establish TLS connection" ]]; then
             join=`/opt/couchbase/bin/couchbase-cli server-add -c http://$ip:$CB_UI_PORT -p $CB_PASS -u $CB_USER \
            --server-add=http://$nodename:$CB_UI_PORT --server-add-username=$CB_USER --server-add-password=$CB_PASS \
            --services=$CB_SERVICES`
         else
             join=`/opt/couchbase/bin/couchbase-cli server-add -c http://$ip:$CB_UI_PORT -p $CB_PASS -u $CB_USER \
            --server-add=http://$nodename:$CB_UI_PORT --server-add-username=$CB_USER --server-add-password=$CB_PASS \
            --services=$CB_SERVICES`
         fi

         echo "Not Joined: $join.";

      done <<< "$private_ips"
      
      echo "Didn't join to any nodes yet, sleeping 10s and retrying"
      sleep 10;
    fi
done

sleep 5
rebalance
######
    dev_preview=`echo 'y' | /opt/couchbase/bin/couchbase-cli enable-developer-preview -c localhost:8091 -u Administrator -p password --enable`
######

##if we come back from rebalance, we are the one that did it.  otherwise we exited
if  [[ "$CB_TRAVEL_DEMO" == "TRUE" ]]; then  
  x=''
  while [[ "$x" != '[]' ]]; do
    echo "Creating travel-sample bucket"
    x=$(curl -u $CB_USER:$CB_PASS http://localhost:$CB_UI_PORT/sampleBuckets/install -d '["travel-sample"]')
    #curl -s -X POST --data \'[\"travel-sample\"]\' http://$ENV{'CB_USER'}:$ENV{'CB_PASS'}\@localhost:$ENV{'CB_UI_PORT'}/sampleBuckets/install > /dev/null
    sleep 5;
  done
fi
