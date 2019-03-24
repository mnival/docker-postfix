Docker debian-postfix
============

Configuration Docker with Debian Stable and package : postfix

Quick Start
===========
    docker run -d -p 25:25 --name mail mnival/debian-postfix

Interfaces
===========

Ports
-------

* 25 -- SMTP

Volumes
-------

* /etc/postfix
* /var/spool/postfix
* /var/lib/postfix
* /var/log/postfix

Maintainer
==========

Please submit all issues/suggestions/bugs via
https://github.com/mnival/doker-postfix
