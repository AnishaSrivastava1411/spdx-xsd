<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:sbom="urn:cyclonedx.org:niem/sbom" version="2.0" exclude-result-prefixes="xs">
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:include href="spdx_map.xsl"/>

    <xsl:variable name="niemxsd">
        <xsl:copy-of select="$additions"/>
        <xsl:apply-templates select="$xsdmap//*" mode="global"/>
    </xsl:variable>

    <xsl:variable name="roottype" select="$niemxsd/xs:element[@name = $RootEl]/@type"/>

    <xsl:template name="main">
        <xsl:result-document href="{$outputxsd}">
            <xs:schema xmlns="urn:cyclonedx.org:niem/sbom" 
                xmlns:ct="http://release.niem.gov/niem/conformanceTargets/3.0/" 
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:spdx="urn:cyclonedx.org:niem/spdx" 
                xmlns:sbom="urn:cyclonedx.org:niem/sbom" 
                xmlns:structures="http://release.niem.gov/niem/structures/4.0/"
                xmlns:xhtml="http://www.w3.org/1999/xhtml-StopBrowserRendering" 
                xmlns:xs="http://www.w3.org/2001/XMLSchema" attributeFormDefault="unqualified" elementFormDefault="unqualified"
                version="1"
                xsi:schemaLocation="http://release.niem.gov/niem/appinfo/4.0/ ext/niem/utility/appinfo/4.0/appinfo.xsd http://release.niem.gov/niem/conformanceTargets/3.0/ ext/niem/utility/conformanceTargets/3.0/conformanceTargets.xsd"
                ct:conformanceTargets="http://reference.niem.gov/niem/specification/naming-and-design-rules/4.0/#ReferenceSchemaDocument" targetNamespace="urn:cyclonedx.org:niem/sbom">
                <xs:import schemaLocation="ext/niem/utility/structures/4.0/structures.xsd" namespace="http://release.niem.gov/niem/structures/4.0/"/>
                <xs:import namespace="urn:cyclonedx.org:niem/spdx" schemaLocation="ext/spdx/spdx-license-niem.xsd"/>
                <xs:annotation>
                    <xs:documentation>NIEM XML Data Encoding for Software Bill Of Material Information using CycloneDX Specification (https://cyclonedx.org)</xs:documentation>
                </xs:annotation>
                <xsl:copy-of select="$niemxsd/xs:element[@name = $RootEl]" copy-namespaces="no"/>
                <xsl:copy-of select="$niemxsd/xs:complexType[@name = $roottype]" copy-namespaces="no"/>
                <xsl:for-each select="$niemxsd/xs:simpleType">
                    <xsl:sort select="@name"/>
                    <xsl:copy-of select="." copy-namespaces="no"/>
                </xsl:for-each>
                <xsl:for-each select="$niemxsd/xs:complexType[not(@name = $roottype)]">
                    <xsl:sort select="@name"/>
                    <xsl:variable name="n" select="@name"/>
                    <xsl:if test="count(preceding-sibling::*[@name = $n]) = 0">
                        <xsl:copy-of select="." copy-namespaces="no"/>
                    </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="$niemxsd/xs:element[not(@name = $RootEl)]">
                    <xsl:sort select="@name"/>
                    <xsl:variable name="n" select="@name"/>
                    <xsl:if test="count(preceding-sibling::*[@name = $n]) = 0">
                        <xsl:copy-of select="." copy-namespaces="no"/>
                    </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="$niemxsd/xs:attribute">
                    <xsl:sort select="@name"/>
                    <xsl:variable name="n" select="@name"/>
                    <xsl:variable name="t" select="@type"/>
                    <xsl:if test="count(preceding-sibling::*[@name = $n and @type = $t]) = 0">
                        <xsl:copy-of select="." copy-namespaces="no"/>
                    </xsl:if>
                </xsl:for-each>
            </xs:schema>
        </xsl:result-document>
        <xsl:result-document href="{$outputmap}">
            <XSDMAP>
                <xsl:copy-of select="$xsdmap"/>
            </XSDMAP>
        </xsl:result-document>
    </xsl:template>

    <xsl:template match="SimpleType" mode="global">
        <xs:simpleType name="{@niemname}">
            <xs:annotation>
                <xs:documentation>
                    <xsl:value-of select="normalize-space(@niemdoc)"/>
                </xs:documentation>
                <xs:appinfo>
                    <sbom:CycloneDX name="{@origname}"/>
                </xs:appinfo>
            </xs:annotation>
            <xs:restriction base="{@niembase}">
                <xsl:apply-templates select="*" mode="makexsd"/>
            </xs:restriction>
        </xs:simpleType>
    </xsl:template>

    <xsl:template match="Enumeration" mode="makexsd">
        <xs:enumeration value="{@value}">
            <xs:annotation>
                <xs:documentation>
                    <xsl:value-of select="@doc"/>
                </xs:documentation>
            </xs:annotation>
        </xs:enumeration>
    </xsl:template>

    <xsl:template match="Pattern" mode="makexsd">
        <xs:pattern value="{@value}"/>
    </xsl:template>

    <xsl:template match="ComplexType" mode="global">
        <xs:complexType name="{@niemname}">
            <xs:annotation>
                <xs:documentation>
                    <xsl:value-of select="normalize-space(@niemdoc)"/>
                </xs:documentation>
                <xs:appinfo>
                    <sbom:CycloneDX name="{@origname}"/>
                </xs:appinfo>
            </xs:annotation>
            <xsl:choose>
                <xsl:when test="contains(@niembase, 'SimpleType')">
                    <xs:simpleContent>
                        <xs:extension base="{@niembase}">
                            <xsl:apply-templates select="*" mode="makexsd"/>
                        </xs:extension>
                    </xs:simpleContent>
                </xsl:when>
                <xsl:otherwise>
                    <xs:complexContent>
                        <xs:extension base="{@niembase}">
                            <xsl:apply-templates select="*" mode="makexsd"/>
                        </xs:extension>
                    </xs:complexContent>
                </xsl:otherwise>
            </xsl:choose>
        </xs:complexType>
        <xsl:if test="Sequence">
            <xs:element name="{concat(substring(@niemname,0,string-length(@niemname)-3),'AugmentationPoint')}" abstract="true">
                <xs:annotation>
                    <xs:documentation>
                        <xsl:value-of select="concat('An augmentation point for ', @niemname)"/>
                    </xs:documentation>
                </xs:annotation>
            </xs:element>
        </xsl:if>
        <xsl:if test=".//Choice">
            <xs:element name="{.//Choice/@substitutionGroup}" abstract="true">
                <xs:annotation>
                    <xs:documentation>
                        <xsl:value-of select="concat('A data concept for a sustitution group for ', replace(@substitutionGroup, 'Abstract', ''))"/>
                    </xs:documentation>
                    <xs:appinfo>
                        <sbom:Choice substitutionGroup="{.//Choice/@substitutionGroup}">
                            <xsl:for-each select=".//Choice/Element">
                                <sbom:Element name="{@niemname}" type="{@niemtype}"/>
                            </xsl:for-each>
                        </sbom:Choice>
                    </xs:appinfo>
                </xs:annotation>
            </xs:element>
        </xsl:if>
    </xsl:template>

    <xsl:template match="Element" mode="global">
        <xs:element name="{@niemname}" type="{@niemtype}">
            <xsl:if test="parent::Choice/@substitutionGroup">
                <xsl:attribute name="substitutionGroup">
                    <xsl:value-of select="parent::Choice/@substitutionGroup"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:attribute name="nillable">
                <xsl:text>true</xsl:text>
            </xsl:attribute>
            <xs:annotation>
                <xs:documentation>
                    <xsl:value-of select="@niemdoc"/>
                </xs:documentation>
                <xs:appinfo>
                    <sbom:CycloneDX name="{@origname}">
                        <xsl:if test="@origtype != ''">
                            <xsl:attribute name="type">
                                <xsl:value-of select="@origtype"/>
                            </xsl:attribute>
                        </xsl:if>
                    </sbom:CycloneDX>
                </xs:appinfo>
            </xs:annotation>
        </xs:element>
        <xsl:if test="@origtype = '' and @niemtype">
            <xs:complexType name="{@niemtype}">
                <xs:annotation>
                    <xs:documentation>
                        <xsl:value-of select="normalize-space(replace(@niemdoc, 'data item', 'data type'))"/>
                    </xs:documentation>
                </xs:annotation>
                <xs:complexContent>
                    <xs:extension base="structures:ObjectType">
                        <xsl:apply-templates select="*" mode="makexsd"/>
                    </xs:extension>
                </xs:complexContent>
            </xs:complexType>
            <xsl:if test="Sequence">
                <xs:element name="{concat(substring(@niemtype,0,string-length(@niemtype)-3),'AugmentationPoint')}" abstract="true">
                    <xs:annotation>
                        <xs:documentation>
                            <xsl:value-of select="concat('An augmentation point for ', @niemtype)"/>
                        </xs:documentation>
                    </xs:annotation>
                </xs:element>
            </xsl:if>
            <xsl:if test="Choice">
                <xs:element name="{concat(substring(@niemtype,0,string-length(@niemtype)-3),'AugmentationPoint')}" abstract="true">
                    <xs:annotation>
                        <xs:documentation>
                            <xsl:value-of select="concat('An augmentation point for ', @niemtype)"/>
                        </xs:documentation>
                    </xs:annotation>
                </xs:element>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <xsl:template match="Attribute" mode="global">
        <xs:attribute name="{@niemname}" type="{@niemtype}">
            <xs:annotation>
                <xs:documentation>
                    <xsl:value-of select="@niemdoc"/>
                </xs:documentation>
                <xs:appinfo>
                    <sbom:CycloneDX name="{@origname}" type="{@origtype}"/>
                </xs:appinfo>
            </xs:annotation>
        </xs:attribute>
    </xsl:template>

    <xsl:template match="Element" mode="makexsd">
        <xs:element ref="{@niemname}">
            <xsl:copy-of select="parent::Sequence/@minOccurs"/>
            <xsl:copy-of select="parent::Sequence/@maxOccurs"/>
            <xsl:copy-of select="@maxOccurs"/>
            <xsl:copy-of select="@minOccurs"/>
            <xsl:copy-of select="@maxOccurs"/>
            <xs:annotation>
                <xs:documentation>
                    <xsl:value-of select="@niemdoc"/>
                </xs:documentation>
            </xs:annotation>
        </xs:element>
    </xsl:template>

    <xsl:template match="Attribute" mode="makexsd">
        <xs:attribute ref="{@niemname}">
            <xsl:copy-of select="@minOccurs"/>
            <xsl:copy-of select="@maxOccurs"/>
            <xs:annotation>
                <xs:documentation>
                    <xsl:value-of select="@niemdoc"/>
                </xs:documentation>
            </xs:annotation>
        </xs:attribute>
    </xsl:template>

    <xsl:template match="Sequence" mode="makexsd">
        <xsl:variable name="parentname">
            <xsl:choose>
                <xsl:when test="parent::Element">
                    <xsl:value-of select="parent::Element[1]/@niemtype"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="ancestor::*[1]/@niemname"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xs:sequence>
            <xsl:apply-templates select="*" mode="makexsd"/>
            <xs:element ref="{concat(substring($parentname,0,string-length($parentname)-3),'AugmentationPoint')}" minOccurs="0" maxOccurs="unbounded"/>
        </xs:sequence>
    </xsl:template>

    <xsl:template match="Choice" mode="makexsd">
        <xsl:variable name="parentname">
            <xsl:choose>
                <xsl:when test="parent::Element">
                    <xsl:value-of select="parent::Element[1]/@niemtype"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="ancestor::*[1]/@niemname"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xs:sequence>
            <xs:element ref="{@substitutionGroup}">
                <xs:annotation>
                    <xs:documentation>
                        <xsl:value-of select="concat('A data concept for a sustitution group for ', replace(@substitutionGroup, 'Abstract', ''))"/>
                    </xs:documentation>
                    <xs:appinfo>
                        <sbom:Choice substitutionGroup="{@substitutionGroup}">
                            <xsl:for-each select="Element">
                                <sbom:Element name="{@niemname}" type="{@niemtype}"/>
                            </xsl:for-each>
                        </sbom:Choice>
                    </xs:appinfo>
                </xs:annotation>
            </xs:element>
            <xs:element ref="{concat(substring($parentname,0,string-length($parentname)-3),'AugmentationPoint')}" minOccurs="0" maxOccurs="unbounded">
                <xs:annotation>
                    <xs:documentation>
                        <xsl:value-of select="concat('An augmentation point for ', $parentname)"/>
                    </xs:documentation>
                </xs:annotation>
            </xs:element>
        </xs:sequence>
    </xsl:template>

    <xsl:template match="Sequence/Choice" mode="makexsd">
        <xs:element ref="{@substitutionGroup}">
            <xs:annotation>
                <xs:documentation>
                    <xsl:value-of select="concat('A data concept for a sustitution group for ', replace(@substitutionGroup, 'Abstract', ''))"/>
                </xs:documentation>
                <xs:appinfo>
                    <sbom:Choice substitutionGroup="{@substitutionGroup}">
                        <xsl:for-each select="Element">
                            <sbom:Element name="{@niemname}" type="{@niemtype}"/>
                        </xsl:for-each>
                    </sbom:Choice>
                </xs:appinfo>
            </xs:annotation>
        </xs:element>
    </xsl:template>

    <xsl:template match="Element[@origname = 'cpe']" mode="global"/>

    <xsl:template match="Element[@origname = 'cpe']" mode="makexsd"/>

</xsl:stylesheet>
