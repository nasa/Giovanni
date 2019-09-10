<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" 
xmlns:java="http://xml.apache.org/xslt/java" exclude-result-prefixes="java">

<xsl:output method="xml" version="1.0" indent="yes" />

<xsl:template match="dataProduct">
  <dataProduct>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductId" />
    <xsl:with-param name="nodeName" select="'dataProductId'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductIdentifiers/value/dataProductDataSetId" />
    <xsl:with-param name="nodeName" select="'dataProductDataSetId'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductIdentifiers/value/dataProductGcmdEntryId" />
    <xsl:with-param name="nodeName" select="'dataProductGcmdEntryId'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductIdentifiers/value/dataProductShortName" />
    <xsl:with-param name="nodeName" select="'dataProductShortName'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductIdentifiers/value/dataProductVersion" />
    <xsl:with-param name="nodeName" select="'dataProductVersion'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductIdentifiers/value/dataProductLongName" />
    <xsl:with-param name="nodeName" select="'dataProductLongName'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductDescriptionUrl" />
    <xsl:with-param name="nodeName" select="'dataProductDescriptionUrl'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductProcessingLevel" />
    <xsl:with-param name="nodeName" select="'dataProductProcessingLevel'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductDataCenter" />
    <xsl:with-param name="nodeName" select="'dataProductDataCenter'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductPlatform/value/dataProductPlatformShortName" />
    <xsl:with-param name="nodeName" select="'dataProductPlatformShortName'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductPlatform/value/dataProductPlatformLongName" />
    <xsl:with-param name="nodeName" select="'dataProductPlatformLongName'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductInstrument/value/dataProductInstrumentShortName" />
    <xsl:with-param name="nodeName" select="'dataProductInstrumentShortName'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductInstrument/value/dataProductInstrumentLongName" />
    <xsl:with-param name="nodeName" select="'dataProductInstrumentLongName'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductPlatformInstrument" />
    <xsl:with-param name="nodeName" select="'dataProductPlatformInstrument'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductSpatialResolution/value/dataProductSpatialResolutionLatitude" />
    <xsl:with-param name="nodeName" select="'dataProductSpatialResolutionLatitude'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductSpatialResolution/value/dataProductSpatialResolutionLongitude" />
    <xsl:with-param name="nodeName" select="'dataProductSpatialResolutionLongitude'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductSpatialResolution/value/dataProductSpatialResolutionUnits" />
    <xsl:with-param name="nodeName" select="'dataProductSpatialResolutionUnits'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductSpatialCoverage/value/dataProductWest" />
    <xsl:with-param name="nodeName" select="'dataProductWest'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductSpatialCoverage/value/dataProductNorth" />
    <xsl:with-param name="nodeName" select="'dataProductNorth'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductSpatialCoverage/value/dataProductEast" />
    <xsl:with-param name="nodeName" select="'dataProductEast'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductSpatialCoverage/value/dataProductSouth" />
    <xsl:with-param name="nodeName" select="'dataProductSouth'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductTemporalCoverage/value/dataProductBeginDateTime" />
    <xsl:with-param name="nodeName" select="'dataProductBeginDateTime'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductTemporalCoverage/value/dataProductEndDateTime" />
    <xsl:with-param name="nodeName" select="'dataProductEndDateTime'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductTemporalCoverage/value/dataProductEndDateTimeLocked" />
    <xsl:with-param name="nodeName" select="'dataProductEndDateTimeLocked'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductTemporalCoverage/value/dataProductTimeFrequency" />
    <xsl:with-param name="nodeName" select="'dataProductTimeFrequency'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductTemporalCoverage/value/dataProductTimeInterval" />
    <xsl:with-param name="nodeName" select="'dataProductTimeInterval'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductTemporalCoverage/value/dataProductStartTimeOffset" />
    <xsl:with-param name="nodeName" select="'dataProductStartTimeOffset'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductTemporalCoverage/value/dataProductEndTimeOffset" />
    <xsl:with-param name="nodeName" select="'dataProductEndTimeOffset'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductSearchIntervalDays" />
    <xsl:with-param name="nodeName" select="'dataProductSearchIntervalDays'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductOsddUrl" />
    <xsl:with-param name="nodeName" select="'dataProductOsddUrl'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductSampleGranuleUrl" />
    <xsl:with-param name="nodeName" select="'dataProductSampleGranuleUrl'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductOpendapUrl" />
    <xsl:with-param name="nodeName" select="'dataProductOpendapUrl'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductResponseFormat" />
    <xsl:with-param name="nodeName" select="'dataProductResponseFormat'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductSpecialFeatures" />
    <xsl:with-param name="nodeName" select="'dataProductSpecialFeatures'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductInternal" />
    <xsl:with-param name="nodeName" select="'dataProductInternal'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductDataFieldIds" />
    <xsl:with-param name="nodeName" select="'dataProductDataFieldIds'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductCanAddNewFields" />
    <xsl:with-param name="nodeName" select="'dataProductCanAddNewFields'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductGcmdLastRevisionDate" />
    <xsl:with-param name="nodeName" select="'dataProductGcmdLastRevisionDate'" />
  </xsl:call-template>
  <xsl:call-template name="basic">
    <xsl:with-param name="node" select="./dataProductLastModified" />
    <xsl:with-param name="nodeName" select="'dataProductLastModified'" />
  </xsl:call-template>
  </dataProduct>
</xsl:template>

<xsl:template name="basic">
  <xsl:param name="node" />
  <xsl:param name="nodeName" />
  <xsl:choose>
    <xsl:when test="$node">
      <xsl:element name="{local-name($node)}">
	<xsl:copy-of select="$node/value"/>
      </xsl:element>
    </xsl:when>
    <xsl:otherwise>
      <xsl:element name="{$nodeName}">
	<xsl:element name="value"/>
      </xsl:element>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="default">
  <xsl:param name="node" />
  <xsl:param name="nodeName" />
  <xsl:param name="defaultValue" />
  <xsl:choose>
    <xsl:when test="$node">
      <xsl:element name="{local-name($node)}">
	<xsl:choose>
	  <xsl:when test="$node/value">
	    <xsl:copy-of select="$node/value"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:element name="value">
	      <xsl:value-of select="$defaultValue" />
	    </xsl:element>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:element>
    </xsl:when>
    <xsl:otherwise>
      <xsl:element name="{$nodeName}">
	<xsl:element name="value">
	  <xsl:value-of select="$defaultValue" />
	</xsl:element>
      </xsl:element>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>

