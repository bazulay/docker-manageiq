set -ex

export DESTDIR="/var/www/miq/vmdb"
source /opt/rh/rh-ruby22/enable

echo "Updating DB config"
cp /database.openshift.yml $DESTDIR/config/database.yml
sed -i s/{{HOST}}/$POSTGRESQL_SERVICE_HOST/g $DESTDIR/config/database.yml
cat $DESTDIR/config/database.yml

echo "Setting up httpd"
mkdir -p "$DESTDIR/log/apache"
mv /etc/httpd/conf.d/ssl.conf{,.orig}
touch /etc/httpd/conf.d/ssl.conf
cp /apache.conf /etc/httpd/conf.d/manageiq.conf

echo "Migrating DB"
export RAILS_ENV=production
bundle exec rake db:migrate
bundle exec rake db:reset

echo "Applying dirty hacks"
export RUBY_GC_HEAP_GROWTH_MAX_SLOTS=300000 # default: no limit
export RUBY_GC_HEAP_INIT_SLOTS=600000 # default: 10000
export RUBY_GC_HEAP_GROWTH_FACTOR=1.25 # default 1.8
export APPLIANCE=true
export MALLOC_ARENA_MAX=1
export MALLOC_MMAP_THRESHOLD=131072
export KEY_ROOT=/var/www/miq/vmdb/certs
export APPLIANCE_PG_CTL=/usr/bin/pg_ctl
export APPLIANCE_PG_DATA=/tmp
export APPLIANCE_PG_SERVICE=postgresql
export APPLIANCE_PG_SCL_NAME=rh-postgresql94
export APPLIANCE_PG_PACKAGE_NAME=${APPLIANCE_PG_SCL_NAME}-postgresql-server
touch /etc/chrony.conf

echo "Starting Memcached"
nohup /usr/bin/memcached -u root &

echo "Starting EVM"
bundle exec rake evm:start

# ManageIQ kills apache during preparation stage
# We should start it as soon as evm:status reports UI worker is ready

SLEEP_TIME=5
ITER=0
until `bundle exec rake evm:status | grep -q MiqUiWorker` || [ $ITER -eq 20 ]; do
   ITER=$(( ITER+1 ))
   sleep $(( SLEEP_TIME ))
done

nohup /usr/sbin/apachectl &

tail -f $DESTDIR/log/evm.log -f $DESTDIR/log/production.log