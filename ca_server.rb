#! /usr/bin/env ruby

require 'rubygems'
require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'resolv'

CERT_PATH          = 'certs'
SIGNED_CERTS_PATH  = 'signed'

opts = {
        :Port               => 8140,
        :Logger             => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
        :SSLEnable          => true,
        :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
        :SSLCertificate     => OpenSSL::X509::Certificate.new(  File.open(File.join(CERT_PATH, 'ca_crt.pem')).read),
        :SSLPrivateKey      => OpenSSL::PKey::RSA.new(          File.open(File.join(CERT_PATH, 'ca_key.pem')).read),
        :SSLCertName        => [ [ "CN",WEBrick::Utils::getservername ] ]
}

class Server  < Sinatra::Base

    get '/:environment/certificate/:certname' do
      if params[:certname] == 'ca'
        content_type 'text/plain'
        send_file File.join(CERT_PATH, 'ca_crt.pem')
      elsif File.exists?(File.join(SIGNED_CERTS_PATH, "#{params[:certname]}.pem"))
        content_type 'text/plain'
        send_file File.join(SIGNED_CERTS_PATH, "#{params[:certname]}.pem")
      else
        halt 404, "Could not find certificate_request #{:certname}"
      end
    end

    get '/:environment/certificate_revocation_list/ca' do
        content_type 'text/plain'
        send_file File.join(CERT_PATH, 'ca_crl.pem')
    end

    put '/:environment/certificate_request/:certname' do
      host = Resolv.new.getname(request.ip)
      puts host
      if validate(host, params[:certname])
        csr = OpenSSL::X509::Request.new(request.body.read)
        key = OpenSSL::PKey::RSA.new File.open(File.join(CERT_PATH, 'ca_key.pem'))
        ca  = OpenSSL::X509::Certificate.new File.open(File.join(CERT_PATH, 'ca_crt.pem'))
        
        cert = OpenSSL::X509::Certificate.new
        cert.serial = 0
        cert.version = 2
        cert.not_before = Time.now - (60*60*24)     # yesterday
        cert.not_after = Time.now + (60*60*24*365)  # one year from now
        
        cert.subject = csr.subject
        cert.public_key = csr.public_key
        cert.issuer = ca.subject
        
        cert.sign(key, OpenSSL::Digest::SHA1.new)
  
        File.open(File.join(SIGNED_CERTS_PATH, "#{params[:certname]}.pem"), 'w') do |file|
          file.write(cert.to_pem)
        end

        status 200
        content_type 'text/yaml'
      else
        halt 403, 'Unauthorized Agent'
      end
    end
    
    not_found do
      halt 404, 'page not found'
    end
    
    helpers do
      def validate(host, certname)
        # add validation logic here
        return true
      end
    end    
end

Rack::Handler::WEBrick.run(Server, opts) do |server|
        [:INT, :TERM].each { |sig| trap(sig) { server.stop } }
end


        # The extensions don't appear to be required.
        
        #extension_factory = OpenSSL::X509::ExtensionFactory.new
        #extension_factory.subject_certificate = cert
        #extension_factory.issuer_certificate = ca
        
        #extension_factory.create_extension 'basicConstraints', 'CA:FALSE'
        #extension_factory.create_extension 'keyUsage', 'nonRepudiation,digitalSignature,keyEncipherment'
        #extension_factory.create_extension 'extendedKeyUsage', 'clientAuth,emailProtection'
        #extension_factory.create_extension 'nsComment', 'Puppet Ruby/OpenSSL Internal Certificate'
        #extension_factory.create_extension 'nsCertType', 'client,email'
        #extension_factory.create_extension 'subjectKeyIdentifier', 'hash'
