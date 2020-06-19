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

echo "Running Couchbase SG Script:"
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

#####Main Execution

if [[ -e /root/.couchbase/cb_sg ]]; then 
  echo "Just start sync gateway:"
  x=`service sync_gateway start`
  if [[ "$x" =~ "FAIL" ]]; then
    echo "Error starting, sleep 5 and then start again:"
    sleep 5
    x=`service sync_gateway start`
  fi
  
  exit 0;
else
  mkdir -p /root/.couchbase/cb_sg
fi

#####Download and install SG package
if [[ "$CB_SG_INSTALL" == "FALSE" ]]; then
  echo "Don't want to install Couchbase Sync Gateway"
  exit 0 # Leave with a smile ...
fi

righttag=`echo $CB_CLUSTER_TAG | sed s/\ /_/`

add_tag "couchbase_sg:$righttag=installed"

x=`echo "$CB_SG_URL" | rev | cut -d'/' -f1 | rev`
echo "Downloading file: $x from $CB_SG_URL"

cd /root
curl -O $CB_SG_URL
 
if [ ! -e $x ] 
then
  curl -O --user 'couchbase:YAN3FrT7k' $CB_SG_URL
fi

if [ ! -e $x ] 
then
  echo "Failed to download $x"
  exit -1
fi

echo "Installing file: $x"  
if [[ "$x" =~ "rpm" ]]
then 
  install=`yum -y install $x`
else
  install=`apt install -y $x`
fi

if [[ "$install" =~ "error" ]]
then
  echo "Failed to install $x: $install"
  echo "Trying one more time:"
  sleep 20
  if [[ "$x" =~ "rpm" ]]
  then 
    install=`yum -y install $x`
  else
    install=`apt install -y $x`
  fi
fi


#####Connect to Couchbase Cluster
if [[ "$CB_SG_CLUSTER" == "FALSE" ]]; then
  echo "Don't want to cluster Couchbase Sync Gateway"
  exit 0 # Leave with a smile ...
fi

single_data_host="127.0.0.1"
single_query_host="127.0.0.1"
single_index_host="127.0.0.1"
single_fts_host="127.0.0.1"
indexhosts="127.0.0.1"

if [[ "$CB_WAIT_FOR_CLUSTER" == "TRUE" ]]; then
  while [[ "$CB_WAIT_FOR_CLUSTER" == "TRUE" ]]; do
    echo "Searching for rebalance completion of cluster: $CB_CLUSTER_TAG:"
    rebalanced=$(get_by_tag "rebalance:$CB_CLUSTER_TAG")
    if [[ "$rebalanced" == "" ]]; then
      echo "Cluster not yet finished, looping back around"
      sleep 5
      continue;
    fi
    break
  done
fi

echo "Searching for members of cluster: $CB_CLUSTER_TAG:"
private_ips=$(get_by_tag "couchbase:$CB_CLUSTER_TAG")
echo "$private_ips"
      
if [[ "$private_ips" == "" ]]; then
  printf "No IP's"
  exit 0
fi


datahosts=$(while read ip; do
  if [[ "$ip" =~ "data" ]]
  then
    echo "$ip" | cut -d ';' -f1
  fi
done <<< "$private_ips")
  
queryhosts=$(while read ip; do
  if [[ "$ip" =~ "query" ]]
  then
    echo "$ip" | cut -d ';' -f1
  fi
done <<< "$private_ips")
  
indexhosts=$(while read ip; do
  if [[ "$ip" =~ "index" ]]
  then
    echo "$ip" | cut -d ';' -f1
  fi
done <<< "$private_ips")

ftshosts=$(while read ip; do
  if [[ "$ip" =~ "fts" ]]
  then
    echo "$ip" | cut -d ';' -f1
  fi
done <<< "$private_ips")

datahosts=`echo "$datahosts" | sed 's/\ /;/g'`
echo "Data hosts: $datahosts"
single_data_host=`echo "$datahosts" | cut -d';' -f 1 | head -n 1`;
  
queryhosts=`echo "$queryhosts" | sed 's/\ /;/g'`
echo "Query hosts: $queryhosts"
single_query_host=`echo "$queryhosts" | cut -d';' -f 1 | head -n 1`;

indexhosts=`echo "$indexhosts" | sed 's/\ /;/g'`
echo "Index hosts: $indexhosts"
single_index_host=`echo "$indexhosts" | cut -d';' -f 1 | head -n 1`;

ftshosts=`echo "$ftshosts" | sed 's/\ /;/g'`
echo "FTS hosts: $ftshosts"
single_fts_host=`echo "$ftshosts" | cut -d';' -f 1 | head -n 1`;

#sleep 5;

if [[ "$CB_WAIT_FOR_CLUSTER" == "TRUE" ]]; then
  while [[ "$CB_WAIT_FOR_CLUSTER" == "TRUE" ]]; do
    echo "Searching for rebalance status of cluster: $CB_CLUSTER_TAG:"
    rebalanced=$(curl -u $CB_USER:$CB_PASS http://$single_data_host:$CB_UI_PORT/pools/default/ | grep -o \"rebalanceStatus\":\"none\")
    if [[ "$rebalanced" == "" ]]; then
      echo "Cluster not yet finished, looping back around"
      sleep 5
      continue;
    fi
    break
  done
fi

#####Connect to bucket

  
###startup SG
cd /couchbase
mkdir syncgateway
cd syncgateway
if  [[ "$CB_TRAVEL_DEMO" == "TRUE" ]]; then
  curl -O https://raw.githubusercontent.com/couchbaselabs/mobile-travel-sample/master/sync-gateway-config-travelsample.json
  #curl -O https://raw.githubusercontent.com/couchbaselabs/mobile-travel-sample/connect_sv/sync-gateway-config-travelsample.json
  cat sync-gateway-config-travelsample.json | \
     sed s/cb-server/$single_data_host/ | \
     sed s/\"admin\",/\"$CB_USER\",/ | \
     sed s/\"password\",/\"$CB_PASS\",/ \
    > /home/sync_gateway/sync_gateway.json 
    
   #####Wait for travel sample to be done
  numindexes=8
  array=(${indexhosts// / })
  
  echo "Waiting for indexes to come online:"
  while true; do
    x=$(cbc n1ql -u $CB_USER -P $CB_PASS -U http://$single_query_host:$CB_UI_PORT/travel-sample "select count(*) from system:indexes where state = \"online\"" | awk -F '[{}]' '{print $2}' | cut -d':' -f 2 | head -n1)
  
    if [[ "$x" -ge "$numindexes" ]]
    then
      break;
    fi
    sleep 5
  done
  sleep 10
fi

if  [[ "$CB_COUCHMART_DEMO" == "TRUE" ]]; then  
  git clone https://github.com/couchbaselabs/connect-eu-demo
  cd connect-eu-demo/android
  cat sync-gateway-config-xattrs.json | \
  sed s/cb_db_hostname/$single_data_host/ | \
  sed s/cb_bucket_name/$CB_BUCKET/ | \
  sed s/cb_bucket_username/$CB_USER/ | \
  sed s/cb_bucket_password/$CB_PASS/ \
  > /home/sync_gateway/sync_gateway.json 
fi

service sync_gateway restart