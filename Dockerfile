FROM debian:stable-slim

LABEL maintainer="Michael Nival <docker@mn-home.fr>" \
	name="debian-postfix" \
	description="Debian Stable with postfix, rsyslog, supervisor" \
	docker.cmd="docker run -d -p 25:25 --name mail mnival/debian-postfix"

RUN addgroup --system postfix --gid 120 && \
	addgroup --system postdrop --gid 121 && \
	adduser --system --home /var/spool/postfix --no-create-home --disabled-password --ingroup postfix postfix --uid 120

RUN printf "deb http://ftp.debian.org/debian/ stable main\ndeb http://ftp.debian.org/debian/ stable-updates main\ndeb http://security.debian.org/ stable/updates main\n" >> /etc/apt/sources.list.d/stable.list && \
	cat /dev/null > /etc/apt/sources.list && \
	export DEBIAN_FRONTEND=noninteractive && \
	apt update && \
	apt -y --no-install-recommends full-upgrade && \
	apt install -y --no-install-recommends postfix ca-certificates rsyslog logrotate supervisor && \
	postconf -X mydestination myhostname mydomain && \
	rm -f /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/certs/ssl-cert-snakeoil.pem.broken /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/ssl-cert-snakeoil.key.broken && \
	find /etc/ssl/certs -maxdepth 1 -lname ssl-cert-snakeoil.pem -delete > /dev/null 2>&1 || true && \
	echo "UTC" > /etc/timezone && \
	rm /etc/localtime && \
	dpkg-reconfigure tzdata && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/alternatives.log /var/log/dpkg.log /var/log/apt/ /var/cache/debconf/*-old

RUN sed -i 's@^\(.*\)\(\$.*master\) \+&@\1exec \2 -d@' /usr/lib/postfix/sbin/postfix-script && \
	sed -i '/^\$\|^#\|^mail\|^$\|imuxsock/! s/\(.*\)/#\1/; s@/var/log/mail@/var/log/postfix/mail@' /etc/rsyslog.conf
	
RUN tar -C /etc/postfix -czf /root/postfix-config.tgz . && \
	tar -C /var/spool/postfix -czf /root/postfix-spool.tgz . && \
	tar -C /var/lib/postfix -czf /root/postfix-data.tgz .

RUN chmod -x /etc/cron.daily/* && \
	chmod +x /etc/cron.daily/logrotate

ADD supervisor-postfix.conf /etc/supervisor/conf.d/postfix.conf
ADD supervisor-cron.conf /etc/supervisor/conf.d/cron.conf
ADD supervisor-rsyslog.conf /etc/supervisor/conf.d/rsyslog.conf
ADD logrotate-postfix /etc/logrotate.d/postfix
ADD start-postfix /usr/local/bin/

ADD event-supervisor/event-supervisor.sh /usr/local/bin/event-supervisor.sh
ADD event-supervisor/supervisor-eventlistener.conf /etc/supervisor/conf.d/eventlistener.conf
RUN sed -i 's@^\(logfile\)=[a-z|A-Z|/|\.]*@\1=/dev/null@' /etc/supervisor/supervisord.conf

EXPOSE 25

VOLUME ["/etc/postfix", "/var/log/postfix", "/var/spool/postfix", "/var/lib/postfix"]

ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
