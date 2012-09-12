# Proof of Concept CA Server

This is a simple web service that implements a subset of the Puppet CA server API.
It will accept Certificate Signing Requests and return signed certificates.

It can be a drop in replacement for the Puppet master CA if it has access to the
Puppet master's certificate and key. The Puppet master doesn't have to know about
the agent. It just has to be able to validate the agent's certificate.

A simple `validate` hook is provided. Right now, it just returns true, meaning that
it signs everything it sees. You can add any logic you like into that method.

## Simple setup

### On the agent:

* Configure the agent to point to your new CA:
  * `ca_server = myca.mydomain.tld`

### On the master:

* Turn CA support off:
  * `ca = false`

## If you want this to be a drop in for the existing master's CA:

* Place the Puppet master's `ca_*.pem` certs into `certs` on your new CA:
  * `scp root@puppetmaster:/etc/puppetlabs/puppet/ssl/ca/ca_* certs/`

## If you want this to be part of your CA infrastructure:

* Make sure that your Puppet master is configured to accept certificates signed
by your new CA.
* You can either place certificates in the `.../ssl/ca` directory and allow
Puppet to validate connections, or you can configure Apache to terminate.


## If you want to provision agents with the CA certs preinstalled

* The agent's ssl directory should look like this:

        # tree /etc/puppetlabs/puppet/ssl/
        /etc/puppetlabs/puppet/ssl/
        |-- certs
        |   `-- ca.pem
        `-- crl.pem
