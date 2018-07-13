# ecFlow startup script for Harmonie
# Ole Vignes, 15.12.2016

## Recover original HARMONIE system environment
if [ ! -s $ENV_SYSTEM ]; then
   echo "FATAL ERROR: HARMONIE system environment file $ENV_SYSTEM not found!"
   exit 1
fi
. $ENV_SYSTEM

## Start server and determine ECF_HOST and ECF_PORT
 
usernumber=`id -u`
username=`id -nu`

## Default ECF_HOST and ECF_PORT

export ECF_PORT=$((1500+usernumber))
export ECF_HOST=$(hostname)

## Checking if the server is running if not start it 
ecflow_client --port $ECF_PORT --host $ECF_HOST --ping  || \
{ unset LL_CLA; ecflow_start.sh -d $JOBOUTDIR; }
 
## The default values are recovered from ecflow_start.sh 
## ECF_HOST = ECF_HOST

cd $HM_DATA 
echo "ecflow_client --port "$ECF_PORT" --host "$ECF_HOST" --begin" $EXP

## Delete suite before we launch it
 
ecflow_client --port $ECF_PORT --host $ECF_HOST --delete=force yes /$EXP || true

## Load and play the suite

ecflow_client --port $ECF_PORT --host $ECF_HOST --load=${PLAYFILE}.def
ecflow_client --port $ECF_PORT --host $ECF_HOST --begin $EXP

## Set up the server for the ecflow gui
 
echo 'connect:true' > $HOME/.ecflowrc/$username.options 
grep $username $HOME/.ecflowrc/servers || echo $username $ECF_HOST $ECF_PORT > $HOME/.ecflowrc/servers

## Start log server (should be externalized to Env_submit for ecgate-cca)

joboutdirh1=$(echo $JOBOUTDIR | sed 's/\/hpc//')
ssh $ECF_LOGHOST start_logserver -d $joboutdirh1 -m $JOBOUTDIR:$joboutdirh1 -l $joboutdirh1/logsvr.log
 
## Start the ecflow gui if not already running
export DISPLAY
ecflowui=${ECFLOWUI:-ecflow_ui}
 
ps -u $username | grep -q $ecflowui || $ecflowui
