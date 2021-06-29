# NiFi_SSL
How to create Self Signed Certificates specially for NiFi


Step 1: Install OpenSSL, for example on CentOS run:
#yum install openssl
 
Step 2: Generate a CA signing key and certificate:
#openssl genrsa -out ca.key 8192
#openssl req -new -x509 -extensions v3_ca -key ca.key -out ca.crt -days 365
 
(Create CA with Common Name(CN) set with name 'Root CA')
Step 3: Set up the CA directory structure and copy CA key and CA crt created in step 2 to /root/CA/private and /root/CA/certs respectively:
#mkdir -p -m 0700 /root/CA/{certs,crl,newcerts,private}
#mv ca.key /root/CA/private;mv ca.crt /root/CA/certs
 
Step 4: Add required files and set permissions on the ca.key:
#touch /root/CA/index.txt; echo 1000 > /root/CA/serial
#chmod 0400 /root/CA/private/ca.key

Step 5: Edit /etc/pki/tls/openssl.cnf , the default configuration file for openssl utility

In /etc/pki/tls/openssl.cnf

On CA Node :

Under [ CA_default ] section,

From : # copy_extensions = copy
To :   copy_extensions = copy


From : dir		= /etc/pki/CA		# Where everything is kept
To :     dir		= /root/CA		      # Where everything is kept

From : certificate	= $dir/cacert.pem 	# The CA certificate
To :      certificate	= $dir/certs/ca.crt 	# The CA certificate


From: private_key	= $dir/private/cakey.pem# The private key
To :     private_key	= $dir/private/ca.key   # The private key

In [ usr_cert ]  section, add below entry :

extendedKeyUsage = serverAuth, clientAuth


On All Node :

Under [ v3_req ] section, add below entry :

extendedKeyUsage = serverAuth, clientAuth
subjectAltName = DNS:<Hostname>

Step 7: Create a directory which will be used for new csr and certs:
#mkdir /var/tmp/SSL; cd /var/tmp/SSL
 
Step 8: Generate keys and csr using that corresponding key of each host. Make sure the common name portion of the certificate matches the hostname where the certificate will be deployed.
#openssl genrsa -out <Hostname>.key 2048
# openssl req -new -sha256 -key c4579-node2.coelab.cloudera.com.key -out c4579-node2.coelab.cloudera.com.csr -reqexts v3_req
#openssl req -noout -text -in c4579-node2.coelab.cloudera.com.csr 

(Repeat the Step 7 for all the hosts which require cert)








Step 9: Sign the all csr created in Step 7 using the CA 

# openssl ca -in c4579-node2.coelab.cloudera.com.csr  -out c4579-node2.coelab.cloudera.com.crt
#openssl x509 -in <Hostname>.crt -noout -text

Create jks keystore and truststore :
Step 10: Create PKCS12 keystore and convert it to JKS(Repeat this step for all the .key and .crt of each hosts):
#openssl pkcs12 -export -inkey <hostname>.key -in <hostname>.crt -certfile /root/CA/certs/ca.crt -out <hostname>.pfx
#keytool -list -keystore <hostname>.pfx -storetype PKCS12 -v
 
Step 11: Convert the PKCS12 format to JKS:
#keytool -v -importkeystore -srckeystore <hostname>.pfx -srcstoretype PKCS12 -destkeystore <hostname>.jks -deststoretype JKS -srcalias 1 -destalias <hostname>
 
Step 12: Create a common truststore (as we have signed with CA cert we only need the CA cert in truststore):
#keytool -import -keystore truststore.jks -alias rootca -file ca.crt
#cp truststore.jks all.jks

Step 13: Create a central directory to store the keystore & truststore.

#mkdir /var/private/nifi/ssl
#cp keystore.jks truststore.jks /var/private/nifi/ssl/



Useful Links :
 
https://github.com/Raghav-Guru/hadoopssl
https://access.redhat.com/solutions/28965
https://www.phildev.net/ssl/opensslconf.html
https://jamielinux.com/docs/openssl-certificate-authority/introduction.html
https://stackoverflow.com/questions/30977264/subject-alternative-name-not-present-in-certificate
https://access.redhat.com/solutions/28965
