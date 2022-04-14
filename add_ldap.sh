#!/bin/bash
#Script to Install LDAP & Add LDAP Users

LOC="/tmp"


install_ldap()
{
yum clean all
# install needed ldap packages
yum install -y openldap openldap-clients openldap-servers

# Copy sample Ldap DBs
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
chown ldap:ldap /var/lib/ldap/*
chown ldap. /var/lib/ldap/DB_CONFIG

setenforce 0

systemctl start slapd
systemctl enable slapd
sleep 10
cd /etc/openldap/slapd.d/
# set env variable with encrypted password (nifitest)
myPASS={SSHA}idfmF3JQsot6L7hAbuCVG5hhtIb8Nwo5

echo "# specify the password generated above for "olcRootPW" section
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcRootPW
olcRootPW: $myPASS" > chrootpw.ldif

ldapadd -Y EXTERNAL -H ldapi:/// -f chrootpw.ldif

echo "# replace to your own domain name for "dc=***,dc=***" section
# specify the password generated above for "olcRootPW" section
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth"
  read by dn.base="cn=Manager,dc=nifi,dc=hwx" read by * none
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=nifi,dc=hwx
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=Manager,dc=nifi,dc=hwx
dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcRootPW
olcRootPW: $myPASS
dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {0}to attrs=userPassword,shadowLastChange by
  dn="cn=Manager,dc=nifi,dc=hwx" write by anonymous auth by self write by * none
olcAccess: {1}to dn.base="" by * read
olcAccess: {2}to * by dn="cn=Manager,dc=nifi,dc=hwx" write by * read" > chdomain.ldif

ldapmodify -Y EXTERNAL -H ldapi:/// -f chdomain.ldif

ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

echo "dn: cn=module,cn=config
objectClass: olcModuleList
cn: module
olcModulepath: /usr/lib64/openldap
olcModuleload: memberof.la
olcModuleload: refint.la" > module.ldif

echo "dn: olcOverlay={0}memberof,olcDatabase={2}hdb,cn=config
objectClass: olcConfig
objectClass: olcMemberOf
objectClass: olcOverlayConfig
objectClass: top
olcOverlay: memberof" > memberof.ldif

echo "dn: olcOverlay={1}refint,olcDatabase={2}hdb,cn=config
objectClass: olcConfig
objectClass: olcOverlayConfig
objectClass: olcRefintConfig
objectClass: top
olcOverlay: {1}refint
olcRefintAttribute: memberof member manager owner" > refint.ldif

ldapadd -Y EXTERNAL -H ldapi:/// -f module.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f memberof.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f refint.ldif

echo "# replace to your own domain name for "dc=***,dc=***" section
dn: dc=nifi,dc=hwx
objectClass: top
objectClass: dcObject
objectclass: organization
o: nifi hwx
dc: nifi
dn: cn=Manager,dc=nifi,dc=hwx
objectClass: organizationalRole
cn: Manager
description: Directory Manager
dn: ou=People,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: People
dn: ou=Group,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: Group
dn: ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: SupportAcct
dn: ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: SupportFLE
dn: ou=SupportSME,ou=Group,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: SupportSME
dn: ou=SupportORG,ou=Group,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: SupportORG
dn: ou=BreakFix,ou=Group,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: BreakFix
dn: ou=NiFiSME,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: NiFiSME
dn: ou=AdminTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: AdminTeam1
dn: ou=AdminTeam2,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: AdminTeam2
dn: ou=AcctTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: AcctTeam1
dn: ou=AcctTeam2,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: AcctTeam2
dn: ou=FLETeam1,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: FLETeam1
dn: ou=FLETeam2,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: FLETeam2
dn: ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: DFM
dn: ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: Operations
dn: ou=Monitor,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: Monitor
dn: ou=BFEastTeam,ou=BreakFix,ou=Group,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: BFEastTeam
dn: ou=BFWestTeam,ou=BreakFix,ou=Group,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: BFWestTeam
dn: ou=SMETeam1,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: SMETeam1
dn: ou=SMETeam2,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
objectClass: organizationalUnit
ou: SMETeam2" > basedomain.ldif

ldapadd -x -D cn=Manager,dc=nifi,dc=hwx -w nifitest -f basedomain.ldif

echo "dn: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
changetype: add
uid: nifiadmin
cn: nifiadmin
sn: nifiadmin
objectClass: top
objectClass: inetOrgPerson
objectclass: person
objectclass: organizationalPerson
memberOf: cn=admins,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiadmins1,ou=AdminTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiadmins2,ou=AdminTeam2,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=AcctManager,ou=AcctTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiAcct,ou=AcctTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=AcctSupervisor,ou=AcctTeam2,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=FLEeast,ou=FLETeam1,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiFLEeast,ou=FLETeam1,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=FLEwest,ou=FLETeam2,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiFLEwest,ou=FLETeam2,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=SMEeast,ou=SMETeam1,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiSMEeast,ou=SMETeam1,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
memberOf: cn=SMEwest,ou=SMETeam2,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiSMEwest,ou=SMETeam2,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiDFMeast,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiDFMwest,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiDFMother,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiOPEReast,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiOPERwest,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiOPERother,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiMONeast,ou=Monitor,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiMONwest,ou=Monitor,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiMONother,ou=Monitor,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiDFM,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiOPER,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiBFeast,ou=BFEastTeam,ou=BreakFix,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiBFwest,ou=BFWestTeam,ou=BreakFix,ou=Group,dc=nifi,dc=hwx
memberOf: cn=managerTeam1,ou=FLETeam1,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=managerTeam2,ou=FLETeam2,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
dn: cn=nifi.admin.1,ou=People,dc=nifi,dc=hwx
changetype: add
uid: nifiadmin1
cn: nifiadmin1
sn: nifiadmin1
objectClass: top
objectClass: inetOrgPerson
objectclass: person
objectclass: organizationalPerson
memberOf: cn=nifiadmins1,ou=AdminTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=AcctManager,ou=AcctTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiAcct,ou=AcctTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=AcctSupervisor,ou=AcctTeam2,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=FLEeast,ou=FLETeam1,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiFLEeast,ou=FLETeam1,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=SMEeast,ou=SMETeam1,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiSMEeast,ou=SMETeam1,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiMONeast,ou=Monitor,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiDFM,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
dn: cn=nifi.admin.2,ou=People,dc=nifi,dc=hwx
changetype: add
uid: nifiadmin2
cn: nifiadmin2
sn: nifiadmin2
objectClass: top
objectClass: inetOrgPerson
objectclass: person
objectclass: organizationalPerson
memberOf: cn=nifiadmins1,ou=AdminTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=AcctManager,ou=AcctTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiAcct,ou=AcctTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=AcctSupervisor,ou=AcctTeam2,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=FLEeast,ou=FLETeam1,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiFLEeast,ou=FLETeam1,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=SMEeast,ou=SMETeam1,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiSMEeast,ou=SMETeam1,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiMONeast,ou=Monitor,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiDFM,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
dn: cn=nifi.admin.3,ou=People,dc=nifi,dc=hwx
changetype: add
uid: nifiadmin3
cn: nifiadmin3
sn: nifiadmin3
objectClass: top
objectClass: inetOrgPerson
objectclass: person
objectclass: organizationalPerson
memberOf: cn=nifiadmins2,ou=AdminTeam2,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=AcctSupervisor,ou=AcctTeam2,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=FLEwest,ou=FLETeam2,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiFLEwest,ou=FLETeam2,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=SMEwest,ou=SMETeam2,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiSMEwest,ou=SMETeam2,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiDFM,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
dn: cn=nifi.admin.4,ou=People,dc=nifi,dc=hwx
changetype: add
uid: nifiadmin4
cn: nifiadmin4
sn: nifiadmin4
objectClass: top
objectClass: inetOrgPerson
objectclass: person
objectclass: organizationalPerson
memberOf: cn=nifiadmins2,ou=AdminTeam2,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=AcctSupervisor,ou=AcctTeam2,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=FLEwest,ou=FLETeam2,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiFLEwest,ou=FLETeam2,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=SMEwest,ou=SMETeam2,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiSMEwest,ou=SMETeam2,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiDFM,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
dn: cn=nifi.user.1,ou=People,dc=nifi,dc=hwx
changetype: add
uid: nifiuser1
cn: nifiuser1
sn: nifiuser1
objectClass: top
objectClass: inetOrgPerson
objectclass: person
objectclass: organizationalPerson
memberOf: cn=AcctManager,ou=AcctTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiAcct,ou=AcctTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=FLEeast,ou=FLETeam1,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiFLEeast,ou=FLETeam1,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiMONeast,ou=Monitor,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiDFMeast,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiOPER,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiOPEReast,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=users,ou=Group,dc=nifi,dc=hwx
dn: cn=nifi.user.2,ou=People,dc=nifi,dc=hwx
changetype: add
uid: nifiuser2
cn: nifiuser2
sn: nifiuser2
objectClass: top
objectClass: inetOrgPerson
objectclass: person
objectclass: organizationalPerson
memberOf: cn=AcctSupervisor,ou=AcctTeam2,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=FLEwest,ou=FLETeam2,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiFLEwest,ou=FLETeam2,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiDFMwest,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiOPER,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiOPERwest,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=users,ou=Group,dc=nifi,dc=hwx
dn: cn=nifi.user.3,ou=People,dc=nifi,dc=hwx
changetype: add
uid: nifiuser3
cn: nifiuser3
sn: nifiuser3
objectClass: top
objectClass: inetOrgPerson
objectclass: person
objectclass: organizationalPerson
memberOf: cn=AcctManager,ou=AcctTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiAcct,ou=AcctTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=FLEeast,ou=FLETeam1,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiFLEeast,ou=FLETeam1,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiMONeast,ou=Monitor,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiDFMeast,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiOPER,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiOPEReast,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=users,ou=Group,dc=nifi,dc=hwx
dn: cn=nifi.user.4,ou=People,dc=nifi,dc=hwx
changetype: add
uid: nifiuser4
cn: nifiuser4
sn: nifiuser4
objectClass: top
objectClass: inetOrgPerson
objectclass: person
objectclass: organizationalPerson
memberOf: cn=AcctSupervisor,ou=AcctTeam2,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=FLEwest,ou=FLETeam2,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiFLEwest,ou=FLETeam2,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiDFMwest,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiOPER,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiOPERwest,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=users,ou=Group,dc=nifi,dc=hwx
dn: cn=nifi.sme.1,ou=People,dc=nifi,dc=hwx
changetype: add
uid: nifisme1
cn: nifisme1
sn: nifisme1
objectClass: top
objectClass: inetOrgPerson
objectclass: person
objectclass: organizationalPerson
memberOf: cn=AcctSupervisor,ou=AcctTeam2,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=FLEeast,ou=FLETeam1,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiFLEeast,ou=FLETeam1,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=SMEeast,ou=SMETeam1,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiSMEeast,ou=SMETeam1,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiDFMeast,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiOPEReast,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiMONeast,ou=Monitor,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiDFM,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiOPER,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiBFeast,ou=BFEastTeam,ou=BreakFix,ou=Group,dc=nifi,dc=hwx
memberOf: cn=sme,ou=Group,dc=nifi,dc=hwx
dn: cn=nifi.sme.2,ou=People,dc=nifi,dc=hwx
changetype: add
uid: nifisme2
cn: nifisme2
sn: nifisme2
objectClass: top
objectClass: inetOrgPerson
objectclass: person
objectclass: organizationalPerson
memberOf: cn=AcctManager,ou=AcctTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=FLEwest,ou=FLETeam2,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiFLEwest,ou=FLETeam2,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=SMEwest,ou=SMETeam2,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiSMEwest,ou=SMETeam2,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiDFMwest,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiOPERwest,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiMONwest,ou=Monitor,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiDFM,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiOPER,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiBFwest,ou=BFWestTeam,ou=BreakFix,ou=Group,dc=nifi,dc=hwx
memberOf: cn=sme,ou=Group,dc=nifi,dc=hwx
dn: cn=nifi.sme.3,ou=People,dc=nifi,dc=hwx
changetype: add
uid: nifisme3
cn: nifisme3
sn: nifisme3
objectClass: top
objectClass: inetOrgPerson
objectclass: person
objectclass: organizationalPerson
memberOf: cn=AcctSupervisor,ou=AcctTeam2,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=FLEeast,ou=FLETeam1,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiFLEeast,ou=FLETeam1,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=SMEeast,ou=SMETeam1,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiSMEeast,ou=SMETeam1,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiDFMeast,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiOPEReast,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiMONeast,ou=Monitor,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiDFM,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiOPER,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiBFeast,ou=BFEastTeam,ou=BreakFix,ou=Group,dc=nifi,dc=hwx
memberOf: cn=sme,ou=Group,dc=nifi,dc=hwx
dn: cn=nifi.sme.4,ou=People,dc=nifi,dc=hwx
changetype: add
uid: nifisme4
cn: nifisme4
sn: nifisme4
objectClass: top
objectClass: inetOrgPerson
objectclass: person
objectclass: organizationalPerson
memberOf: cn=AcctManager,ou=AcctTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=FLEwest,ou=FLETeam2,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiFLEwest,ou=FLETeam2,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=SMEwest,ou=SMETeam2,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiSMEwest,ou=SMETeam2,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiDFMwest,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiOPERwest,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiMONwest,ou=Monitor,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiDFM,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiOPER,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiBFwest,ou=BFWestTeam,ou=BreakFix,ou=Group,dc=nifi,dc=hwx
memberOf: cn=sme,ou=Group,dc=nifi,dc=hwx
dn: cn=nifi.bf.1,ou=People,dc=nifi,dc=hwx
changetype: add
uid: nifibf1
cn: nifibf1
sn: nifibf1
objectClass: top
objectClass: inetOrgPerson
objectclass: person
objectclass: organizationalPerson
memberOf: cn=nifiDFMeast,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiBFeast,ou=BFEastTeam,ou=BreakFix,ou=Group,dc=nifi,dc=hwx
dn: cn=nifi.bf.2,ou=People,dc=nifi,dc=hwx
changetype: add
uid: nifibf2
cn: nifibf2
sn: nifibf2
objectClass: top
objectClass: inetOrgPerson
objectclass: person
objectclass: organizationalPerson
memberOf: cn=nifiDFMwest,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
memberOf: cn=nifiBFwest,ou=BFWestTeam,ou=BreakFix,ou=Group,dc=nifi,dc=hwx
dn: cn=nifi.manager.1,ou=People,dc=nifi,dc=hwx
changetype: add
uid: nifimanager1
cn: nifimanager1
sn: nifimanager1
objectClass: top
objectClass: inetOrgPerson
objectclass: person
objectclass: organizationalPerson
memberOf: cn=AcctManager,ou=AcctTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=AcctSupervisor,ou=AcctTeam2,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=managerTeam1,ou=FLETeam1,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=managers,ou=Group,dc=nifi,dc=hwx
dn: cn=nifi.manager.2,ou=People,dc=nifi,dc=hwx
changetype: add
uid: nifimanager2
cn: nifimanager2
sn: nifimanager2
objectClass: top
objectClass: inetOrgPerson
objectclass: person
objectclass: organizationalPerson
memberOf: cn=AcctManager,ou=AcctTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=AcctSupervisor,ou=AcctTeam2,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
memberOf: cn=managerTeam2,ou=FLETeam2,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
memberOf: cn=managers,ou=Group,dc=nifi,dc=hwx
dn: cn=admins,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: admins
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
dn: cn=users,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: users
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.4,ou=People,dc=nifi,dc=hwx
dn: cn=sme,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: sme
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.4,ou=People,dc=nifi,dc=hwx
dn: cn=managers,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: managers
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.manager.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.manager.2,ou=People,dc=nifi,dc=hwx
dn: cn=nifiadmins1,ou=AdminTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: nifiadmins1
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.2,ou=People,dc=nifi,dc=hwx
dn: cn=nifiadmins2,ou=AdminTeam2,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: nifiadmins2
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.4,ou=People,dc=nifi,dc=hwx
dn: cn=AcctManager,ou=AcctTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: AcctManager
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.4,ou=People,dc=nifi,dc=hwx
member: cn=nifi.manager.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.manager.2,ou=People,dc=nifi,dc=hwx
dn: cn=nifiAcct,ou=AcctTeam1,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: nifiAcct
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.3,ou=People,dc=nifi,dc=hwx
dn: cn=AcctSupervisor,ou=AcctTeam2,ou=SupportAcct,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: AcctSupervisor
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.4,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.4,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.manager.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.manager.2,ou=People,dc=nifi,dc=hwx
dn: cn=FLEeast,ou=FLETeam1,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: FLEeast
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.3,ou=People,dc=nifi,dc=hwx
dn: cn=nifiFLEeast,ou=FLETeam1,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: nifiFLEeast
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.3,ou=People,dc=nifi,dc=hwx
dn: cn=FLEwest,ou=FLETeam2,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: FLEwest
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.4,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.4,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.4,ou=People,dc=nifi,dc=hwx
dn: cn=nifiFLEwest,ou=FLETeam2,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: nifiFLEwest
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.4,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.4,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.4,ou=People,dc=nifi,dc=hwx
dn: cn=SMEeast,ou=SMETeam1,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: SMEeast
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.3,ou=People,dc=nifi,dc=hwx
dn: cn=nifiSMEeast,ou=SMETeam1,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: nifiSMEeast
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.3,ou=People,dc=nifi,dc=hwx
dn: cn=SMEwest,ou=SMETeam2,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: SMEwest
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.4,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.4,ou=People,dc=nifi,dc=hwx
dn: cn=nifiSMEwest,ou=SMETeam2,ou=SupportSME,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: nifiSMEwest
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.4,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.4,ou=People,dc=nifi,dc=hwx
dn: cn=nifiDFMeast,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: nifiDFMeast
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.bf.1,ou=People,dc=nifi,dc=hwx
dn: cn=nifiDFMwest,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: nifiDFMwest
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.4,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.4,ou=People,dc=nifi,dc=hwx
member: cn=nifi.bf.2,ou=People,dc=nifi,dc=hwx
dn: cn=nifiDFMother,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: nifiDFMother
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
dn: cn=nifiOPEReast,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: nifiOPEReast
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.3,ou=People,dc=nifi,dc=hwx
dn: cn=nifiOPERwest,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: nifiOPERwest
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.4,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.4,ou=People,dc=nifi,dc=hwx
dn: cn=nifiOPERother,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: nifiOPERother
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
dn: cn=nifiMONeast,ou=Monitor,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: nifiMONeast
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.3,ou=People,dc=nifi,dc=hwx
dn: cn=nifiMONwest,ou=Monitor,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: nifiMONwest
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.4,ou=People,dc=nifi,dc=hwx
dn: cn=nifiMONother,ou=Monitor,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: nifiMONother
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
dn: cn=nifiDFM,ou=DFM,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: nifiDFM
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.admin.4,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.4,ou=People,dc=nifi,dc=hwx
dn: cn=nifiOPER,ou=Operations,ou=SupportORG,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: nifiOPER
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.user.4,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.4,ou=People,dc=nifi,dc=hwx
dn: cn=nifiBFeast,ou=BFEastTeam,ou=BreakFix,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: nifiBFeast
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.1,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.3,ou=People,dc=nifi,dc=hwx
member: cn=nifi.bf.1,ou=People,dc=nifi,dc=hwx
dn: cn=nifiBFwest,ou=BFWestTeam,ou=BreakFix,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: nifiBFwest
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.2,ou=People,dc=nifi,dc=hwx
member: cn=nifi.sme.4,ou=People,dc=nifi,dc=hwx
member: cn=nifi.bf.2,ou=People,dc=nifi,dc=hwx
dn: cn=managerTeam1,ou=FLETeam1,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: managerTeam1
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.manager.1,ou=People,dc=nifi,dc=hwx
dn: cn=manager2,ou=FLETeam2,ou=SupportFLE,ou=Group,dc=nifi,dc=hwx
objectClass: top
objectClass: groupOfNames
cn: managerTeam2
member: cn=nifi.admin,ou=People,dc=nifi,dc=hwx
member: cn=nifi.manager.2,ou=People,dc=nifi,dc=hwx" > baseusers.ldif

ldapadd -x -D cn=Manager,dc=nifi,dc=hwx -w nifitest -f baseusers.ldif

ldappasswd -x -D "cn=Manager,dc=nifi,dc=hwx" -w nifitest -s nifitest "cn=nifi.user.1,ou=People,dc=nifi,dc=hwx"
ldappasswd -x -D "cn=Manager,dc=nifi,dc=hwx" -w nifitest -s nifitest "cn=nifi.user.2,ou=People,dc=nifi,dc=hwx"
ldappasswd -x -D "cn=Manager,dc=nifi,dc=hwx" -w nifitest -s nifitest "cn=nifi.user.3,ou=People,dc=nifi,dc=hwx"
ldappasswd -x -D "cn=Manager,dc=nifi,dc=hwx" -w nifitest -s nifitest "cn=nifi.user.4,ou=People,dc=nifi,dc=hwx"
ldappasswd -x -D "cn=Manager,dc=nifi,dc=hwx" -w nifitest -s nifitest "cn=nifi.admin,ou=People,dc=nifi,dc=hwx"
ldappasswd -x -D "cn=Manager,dc=nifi,dc=hwx" -w nifitest -s nifitest "cn=nifi.admin.1,ou=People,dc=nifi,dc=hwx"
ldappasswd -x -D "cn=Manager,dc=nifi,dc=hwx" -w nifitest -s nifitest "cn=nifi.admin.2,ou=People,dc=nifi,dc=hwx"
ldappasswd -x -D "cn=Manager,dc=nifi,dc=hwx" -w nifitest -s nifitest "cn=nifi.admin.3,ou=People,dc=nifi,dc=hwx"
ldappasswd -x -D "cn=Manager,dc=nifi,dc=hwx" -w nifitest -s nifitest "cn=nifi.admin.4,ou=People,dc=nifi,dc=hwx"
ldappasswd -x -D "cn=Manager,dc=nifi,dc=hwx" -w nifitest -s nifitest "cn=nifi.sme.2,ou=People,dc=nifi,dc=hwx"
ldappasswd -x -D "cn=Manager,dc=nifi,dc=hwx" -w nifitest -s nifitest "cn=nifi.sme.1,ou=People,dc=nifi,dc=hwx"
ldappasswd -x -D "cn=Manager,dc=nifi,dc=hwx" -w nifitest -s nifitest "cn=nifi.sme.4,ou=People,dc=nifi,dc=hwx"
ldappasswd -x -D "cn=Manager,dc=nifi,dc=hwx" -w nifitest -s nifitest "cn=nifi.sme.3,ou=People,dc=nifi,dc=hwx"
ldappasswd -x -D "cn=Manager,dc=nifi,dc=hwx" -w nifitest -s nifitest "cn=nifi.bf.1,ou=People,dc=nifi,dc=hwx"
ldappasswd -x -D "cn=Manager,dc=nifi,dc=hwx" -w nifitest -s nifitest "cn=nifi.bf.2,ou=People,dc=nifi,dc=hwx"
ldappasswd -x -D "cn=Manager,dc=nifi,dc=hwx" -w nifitest -s nifitest "cn=nifi.manager.1,ou=People,dc=nifi,dc=hwx"
ldappasswd -x -D "cn=Manager,dc=nifi,dc=hwx" -w nifitest -s nifitest "cn=nifi.manager.2,ou=People,dc=nifi,dc=hwx"

}

install_ldap|tee -a $LOC/add_ldap.log
